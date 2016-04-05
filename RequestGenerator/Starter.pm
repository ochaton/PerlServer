#!/usr/bin/perl
package RequestGenerator::Starter;
use strict;
use warnings;
use feature 'say';

our $VERSION = '1.0';

use IO::Socket;

use base qw(Exporter);
our @EXPORT_OK = qw( start_server );
our @EXPORT = qw( start_server );

use FindBin;

sub start_server {
	my ($port, $config) = @_;
	my $server = IO::Socket::INET->new( %{$config->{config}} ) 
        or die '[CalculatorKernel] Can\'t create server on port ' . $config->{config}{LocalPort} . ": $@ $/";

    print '[RequestGenerator] Server started on port ' . $config->{config}{LocalPort} . $/;

    
}