#!/usr/bin/perl
package CalculationKernel::Starter;
use strict;
use warnings;

use IO::Socket;
use JSON::XS;

use POSIX qw ( mkfifo );

use CalculationKernel::Logger qw ( logger );

our $VERSION = '2.0';

use base qw(Exporter);
our @EXPORT_OK = qw( start_server );
our @EXPORT = qw( start_server );


my $config_file = '../multi_worker.json';
my $log_file = '../log.pipe';
my $LOG;
my $server;

sub server_kill {
    until (waitpid(-1, 0) == -1) {  }

    unlink($log_file);

    close($server) if $server;

    close($LOG);
    exit(0);
}

sub get_config {
    my $port = shift;
    my $config;
    if (-e $config_file and !-z $config_file) {

        open (my $fh, '<', $config_file);
        
        my $lines;
        (chomp($_), $lines .= $_) while (<$fh>);

        my $src = JSON::XS::decode_json($lines);

        for (@$src) {
            $config = $_;
            last if ($config->{name} eq 'CalculationKernel');
            $config = undef;
        }

        close($fh);
    }

    unless ($config) {
        $config = { config => 
            {
                LocalPort => $port,
                Type => SOCK_STREAM,
                Reuse_Addr => 1,
                Listen => 2
            }
        };
    }
    return $config;
}

sub _start_server {
    my $config = shift;
    my $server = IO::Socket::INET->new( %{$config->{config}} ) 
        or die 'Can\'t create server on port ' . $config->{config}{LocalPort} . ": $@ $/";

    print "Server started\n";

    return $server;
}

sub start_logger {
    if (-e $log_file) {
        unlink($log_file);
    }

    mkfifo($log_file, 0770) 
        or die 'Can\'t create ' . "$log_file: $@ $/";

    logger($log_file);
}

sub start_server {
    my $port = shift;

    $SIG{INT} = \&server_kill;

    my $config = get_config($port);
    my $server = _start_server($config);

    start_logger();

    server_kill();
}

# start_server(9000);

1;