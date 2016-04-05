#!/usr/bin/perl
use strict;
use warnings;

use CalculationKernel::Starter qw ( start_server ); 

our $VERSION = '1.0';

CalculationKernel::Starter::start_server(8800);
