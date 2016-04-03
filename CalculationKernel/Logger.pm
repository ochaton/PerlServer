#!/usr/bin/perl
package CalculationKernel::Logger;

use strict;
use warnings;

our $VERSION = '1.0';

use base qw(Exporter);
our @EXPORT_OK = qw( logger );
our @EXPORT = qw( logger );

sub logger {
    my $log_file = shift;

    return 0 if (!-e $log_file);

    unless (fork()) {
        open (my $LOG, '<', $log_file);
        open (my $LOGGER, '>', '../server.log');

        $LOGGER->print($_ . "\n") while (<$LOG>) ;
        
        $LOGGER->print("Logger Stoped\n");
        close($LOGGER);
        exit(0);
    }
    1;
}

1;
