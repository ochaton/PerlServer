#!/usr/bin/perl
package CalculationKernel::Starter;
use strict;
use warnings;

use feature 'say';

use IO::Socket;
use JSON::XS;

use POSIX qw ( mkfifo );

use CalculationKernel::Logger qw ( logger );
use CalculationKernel::Listenner qw ( listenner );

our $VERSION = '2.0';

use base qw(Exporter);
our @EXPORT_OK = qw( start_server );
our @EXPORT = qw( start_server );

use FindBin;

my $config_file = "$FindBin::Bin/./multi_worker.json";
my $log_file = "$FindBin::Bin/./log.pipe";
my $LOG;
my $log_pid;
my $listenner_pid;
my $server;

sub server_kill {

    print '[CalculatorKernel] Starter: prepare to kill' . $/;

    kill 2, $listenner_pid; # send SIGINT
    kill 2, $log_pid;       # send SIGINT
    close ($LOG);

    until (waitpid(-1, 0) == -1) {  }

    unlink($log_file);
    print '[CalculationKernel] Log file ' . $log_file . ' was deleted' . $/;

    close($server) if $server;

    exit(0);
}

sub _start_server {
    my $config = shift;
    my $server = IO::Socket::INET->new( %{$config->{config}} ) 
        or die '[CalculatorKernel] Can\'t create server on port ' . $config->{config}{LocalPort} . ": $@ $/";

    print '[CalculationKernel] Server started on port ' . $config->{config}{LocalPort} . $/;

    return $server;
}

sub start_logger {
    if (-e $log_file) {
        unlink($log_file);
    }

    mkfifo($log_file, 0770) 
        or die 'Can\'t create ' . "$log_file: $@ $/";

    print '[CalculationKernel] Log File ' . $log_file . ' created successfully' . $/; 

    return logger($log_file);
}

sub start_server {
    my ($port, $config) = @_;

    $SIG{INT} = \&server_kill;

    my $server = _start_server($config);

    ($LOG, $log_pid) = start_logger();

    $listenner_pid = fork();
    unless ($listenner_pid) {
        listenner($server, $config->{clients}, $LOG);
        exit(0);    # save :)
    }

    until (waitpid(-1, 0) == -1) {  };
}

# start_server(9000);

1;