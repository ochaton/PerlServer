#!/usr/bin/perl
package CalculationKernel::Logger;

use strict;
use warnings;

our $VERSION = '1.0';

use base qw(Exporter);
our @EXPORT_OK = qw( logger );
our @EXPORT = qw( logger );

use FindBin;
my $server_log = "$FindBin::Bin" . '/./server.log';

sub logger {
    my $log_file = shift;

    return 0 if (!-e $log_file);

    my $log_pid = fork();
    unless ( $log_pid ) {
        open (my $LOGGER, '>', $server_log);
        open (my $LOG, '<', $log_file) or 
            die 'Can\'t open for read ' . "$log_file: $@ $/";

        $LOG->autoflush(1);

        $SIG{INT} = sub {
            print 'Logger: Catch interraption' . $/;

            $LOGGER->print('[' . gmtime . '] ' . $_) while (<$LOG>) ;
            $LOGGER->print('[' . gmtime . '] ' . 'Logger Stoped' . $/);
            
            close($LOGGER);
            exit(0);
        };

        $LOGGER->print('[' . gmtime . '] ' . $_) while (<$LOG>) ;
        
        $LOGGER->print('[' . gmtime . '] Logger Stoped' . $/);
        close($LOGGER);
        exit(0);
    }

    open (my $LOG, '>', $log_file) or 
            die 'Can\'t open for write ' . "$log_file: $@ $/";
    $LOG->autoflush(1);

    return ( $LOG, $log_pid );
    1;
}

1;
