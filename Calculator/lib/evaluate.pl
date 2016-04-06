=head1 DESCRIPTION

Эта функция должна принять на вход ссылку на массив, который представляет из себя обратную польскую нотацию,
а на выходе вернуть вычисленное выражение

=cut

use 5.018;
use strict;
use warnings;

no warnings 'experimental';
use FindBin;
require "$FindBin::Bin/./Calculator/lib/rpn.pl";

my $binary_patern = qr/^[\+\-\*\/\^]$/;
my $unary_pattern = qr/^U[\+\-]$/;
my $float_pattern = qr/^(([\d]*(\.[\d]*|)([Ee][\+\-]?\d+))|([\d]*\.[\d]+|\d+))$/;

sub evaluate {
    my $rpn = shift;

    my @st;
    for my $lexeme (@$rpn) {

        given($lexeme) {
            when (qr/^U\-$/) {                                                            # U- operator
                my $arg = pop @st;
                die "Не хватает операндов" unless (defined($arg));
                push @st, -$arg;
            }
            when (qr/^U\+$/) {                                                            # U+ operator
                my $arg = pop @st;
                die "Не хватает операндов" unless (defined($arg));
                push @st, $arg;
            }
            when (qr/$binary_patern/) {                                                    # Binary operator
                my $arg2 = pop @st;
                my $arg1 = pop @st;
                die "Не хватает операндов" unless (defined($arg1) and defined($arg2)) ;

                push @st, $arg1 + $arg2 if ($lexeme eq "+"); 
                push @st, $arg1 - $arg2 if ($lexeme eq "-");
                push @st, $arg1 * $arg2 if ($lexeme eq "*");
                push @st, $arg1 / $arg2 if ($lexeme eq "/");
                push @st, $arg1 ** $arg2 if ($lexeme eq "^");
            }
            when (qr/$float_pattern/) {
                push @st, $lexeme;
            }
            default {
                die "SOMETHING REALLY STRANGE HAPPENS! lexeme = $lexeme";
            }
         }
    }
    my $res = pop @st;
    if ($#st >= 0) {                                                                # Calculation stack has > 1 number => die!
        die "Не хватило операций";
    }

    return $res;
}

1;
