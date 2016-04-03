#!/usr/bin/perl
package CalculationKernel::Listenner;
use strict;
use warnings;

use IO::Handle;
use IO::Socket;

use IPC::Shareable;
use IPC::Shareable qw ( LOCK_SH LOCK_NB LOCK_EX );

use CalculationKernel::Mainframe qw( mainframe );

use List::Util qw/min/;

use base qw(Exporter);
our @EXPORT_OK = qw( listenner );
our @EXPORT = qw( listenner );

use feature 'say';
$| = 1;

use v5.018;

our $glue = 'scalar_glue';
our %options = (
    create    => 0,
    exclusive => 0,
    mode      => 0644,
    destroy   => 0,
);

my ($server, $LOG);
my @local_queue;                 # local client queue

sub new_mainframe {
    my ($server, $glue, $LOG, $queue_ref, $max_client) = @_;
    my @client_queue;
    my @queue = @$queue_ref;

    for (0..$max_client) {
        my $var = shift @queue;
        push @client_queue, $var if (defined $var); 
    }

    print $LOG "Listenner: push $max_client\n";

    unless (fork()) {
        mainframe($server, \@client_queue, $glue, $max_client, $LOG);
        exit;
    }

    # closing openning sockets:
    for (@client_queue) {
        print $LOG "Listenner: closing $_\n";
        close($_);
    }
}

sub alrm_handler {
    print $LOG "Listenner: Alarm!\n";

    print $LOG "Listenner: alarm push " . ($#local_queue + 1) . "\n";
    new_mainframe($server, $glue, $LOG, \@local_queue, $#local_queue + 1);

    undef(@local_queue);

    print $LOG "Listenner: Alarm: The end\n";
};

sub listenner {
    ($server, my $max_client, $LOG) = @_;

    my $client_count;
    tie $client_count, 'IPC::Shareable', $glue, { %options } or 
        die "Listenner::tie died: $!"; 

    $client_count = 0;

    (tied $client_count)->shlock();
    print $LOG "Listenner: tie " . $client_count . "\n"; 
    (tied $client_count)->shunlock();

    print $LOG "Listenner: serever started: $$\n";
    print $LOG "Listenner: max_client = $max_client\n";

    while (1) {
        
        $SIG{ALRM} = \&alrm_handler;
        my $alarm_var = 0;

        while (my $client = $server->accept()) {
            print $LOG "Listenner: new Connection $client\n";

            push @local_queue, $client;

            if ($#local_queue + 1 >= $max_client) {
                alarm 0;            # stop the clock! There's no need in it!
                $alarm_var = 0;
                print $LOG "Listenner: stop the clock\n";

                new_mainframe($server, $glue, $LOG, \@local_queue, min($max_client, $#local_queue + 1));

                undef(@local_queue);
            } 
            else {            # if amount of connections not enough:
                unless ($alarm_var) {
                    alarm(1); $alarm_var = 1;
                    print $LOG "Listenner: start the clock\n";
                } else {
                    # print $LOG "Listenner: clock already started";
                }
            }
        }
        print $LOG "Listenner: I wanna stop...\n";
    }
}

1;
