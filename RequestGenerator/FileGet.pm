#!/usr/bin/perl
package RequestGenerator::FileGet;
use strict;
use warnings;
use feature 'say';

our $VERSION = '1.0';

use IO::Handle;
use Fcntl ':flock';
use Fcntl qw ( SEEK_SET );

use base qw(Exporter);
our @EXPORT_OK = qw( get );
our @EXPORT = qw( get );

use FindBin;

my $file_path =  $FindBin::Bin . '/./calcs.txt';
my $last_pos = 0;
my $buf_len = 256;

sub get {
	my $example_count = shift;
	my @examples;

	while ($example_count > 0) {

		say 'I need ' . $example_count;
		
		my $buf;
		my $read_len = 0;
		while ($read_len < $buf_len) {
			open (my $fh, '<', $file_path) or 
				die '[RequestGenerator] File ' . $file_path . ': ' . $@ . ' ' . $/;

		    flock ($fh, LOCK_SH);
		    seek($fh, $last_pos + $read_len, SEEK_SET);
		    
		    $read_len = read ($fh, $buf, $buf_len - $read_len);
		    $last_pos = tell ($fh);

		    flock ($fh, LOCK_UN);
		    close ($fh);
		}

		my @temp = split '\n', unpack("A$buf_len", $buf);
		while (@temp and $example_count) {
		    push @examples, shift @temp;
		    $example_count -= 1;	
		}
	}
	return \@examples;
}

