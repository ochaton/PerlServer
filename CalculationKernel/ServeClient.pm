#!/usr/bin/perl
package CalculationKernel::ServeClient;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw( calculate );
our @EXPORT = qw( calculate );

use feature 'say';

use v5.018;

use FindBin;
require "$FindBin::Bin/Calculator/calculator";

sub calculate {
	my $example = shift;
	return calculator($example);
}

1;
