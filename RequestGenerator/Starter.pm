#!/usr/bin/perl
package RequestGenerator::Starter;
use strict;
use warnings;
use feature 'say';

our $VERSION = '1.0';

use IO::Socket;
use List::Util qw / min /;
use Fcntl ':flock';

use base qw(Exporter);
our @EXPORT_OK = qw( start_server );
our @EXPORT = qw( start_server );

use RequestGenerator::FileGet;

use FindBin;

sub start_server {
	my ($port, $config) = @_;

	my $server = IO::Socket::INET->new( %{$config->{config}} ) 
        or die '[RequestGenerator] Can\'t create server on port ' . $config->{config}{LocalPort} . ": $@ $/";

    print '[RequestGenerator] Server started on port ' . $config->{config}{LocalPort} . $/;

    my $client;

    $SIG{INT} = sub {
    	print '[RequestGenerator] Stopped' . $/;
    	
    	$client->shutdown(2);
    	close($client);

    	close($server);
    	exit(0);
    };

    while ($client = $server->accept()) {
        my $var = <$client>;

        my $examples_count = unpack("S", $var);		# expected...

        my $ans = RequestGenerator::FileGet::get($examples_count);

        use Data::Dumper;
        say Dumper($ans);

        $client->print('Processing...' . $/);
        $client->shutdown(2);
        close($client);

        $ans = make_request(\%{ $config->{connection} }, $ans, $config->{clients});
    }
}

sub make_request {
	my ($conn, $msg, $clients_count) = @_;

	use Data::Dumper;
	say Dumper($conn);
	
	$clients_count = min (scalar(@$msg), $clients_count);
	my $exampl_len = scalar(@$msg) / $clients_count;

	say '[RequestGenerator] Making new Request...';
	say '[RequestGenerator] Client_count: ' . $clients_count;
	say '[RequestGenerator] Examples Lenght: ' . $exampl_len;
	
	for my $idx (0..$clients_count-1) {
		
		my @arg = splice (@$msg, 0, $exampl_len);
		my @ans;

		unless (fork()) {
			my $socket = IO::Socket::INET->new( %$conn )
				or die "[RequestGenerator] Can't establish connection: $@ $/";
			
			for my $var (@arg) {
				$socket->print(pack("A32", $var . $/));
				my $answer = <$socket>;

				push @ans, unpack("A32", $answer);
			}

			$socket->print(pack("A32", 'END!' . $/));
			$socket->shutdown(2);
			close($socket);

			open (my $fh, '>>', '../answers.txt');
			flock($fh, LOCK_SH);

			for my $idx (0..scalar(@arg)) {
				$fh->print($arg[$idx] . ' = ' . $ans[$idx] . $/);
			}

			flock($fh, LOCK_UN);
			close($fh);

			exit(0);
		}
	}

	until (waitpid (-1, 0) == -1) { };
}

1;