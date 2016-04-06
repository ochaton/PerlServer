=head1 DESCRIPTION

Эта функция должна принять на вход арифметическое выражение,
а на выходе дать ссылку на массив, содержащий обратную польскую нотацию
Один элемент массива - это число или арифметическая операция
В случае ошибки функция должна вызывать die с сообщением об ошибке

=cut

use 5.018;
use strict;
use warnings;

no warnings 'experimental';
use FindBin;
require "$FindBin::Bin/./Calculator/lib/tokenize.pl";

my $unary_pattern = qr/^U[\+\-]$/;
my $float_pattern = qr/^(([\d]*(\.[\d]*|)([Ee][\+\-]?\d+))|([\d]*\.[\d]+|\d+))$/;
my $operator_pattern  = qr/^B[\+\-]|[\*\/\^]$/; 

sub rpn {
	my $expr = shift;
	my $source = tokenize($expr);
	my @rpn;
	my @st;
	my %prior = ("U-" => 3, "U+" => 3, "^" => 3, 
					"*" => 2, "/" => 2,
					"+" => 1, "-" => 1,
					"(" => 0, ")" => 0);

	for my $c (@$source) {
		next if $c =~ /^$/;													# skips empty strings

		given ($c) {
			when (qr/$unary_pattern|^\^$/) { 								# Right-associated operations (Unary of ^)

				while ($#st >= 0 and $prior{$c} < $prior{$st[$#st]}) {
					my $tmp = pop @st;
					push @rpn, $tmp;
				}
				push @st, $c;
			}			
			when (qr/$float_pattern/) {										# Float and Integer Numbers

				push @rpn, 0+"$c";											# Venus!
			}										
			when (qr/$operator_pattern/) {									# Left-associated operations

				$c =~ s/B([\+\-])/$1/;										# Bring back from B[+-] to [+-]
				while ($#st >= 0 and $prior{$c} <= $prior{$st[$#st]}) {
					my $tmp = pop @st;
					push @rpn, $tmp;
				};
				push @st, $c;
			}
			when (qr/\(/) {													# Left Bracket
				push @st, $c;
			}
			when (qr/\)/) {													# Right Bracket

				while ($#st >= 0 and !($st[$#st] eq "(")) {	
					my $tmp = pop @st;										# Pop elements while not '('
					push @rpn, $tmp;	
				};
				if ($#st >= 0) {											# Empty stack => No '(' => die!
					pop @st;
				} else {
					die "Скобки не сбалансированы!\n";
				}
			}
			default {
				die "На вход подалась хрень!:$c\n";
			}
		}

	}
	while ($#st >= 0) {														# Push all stack to @rpn
		my $tmp = pop @st;
		if ($tmp eq "(") {
			die "Скобки не сбалансированы!\n";
		}
		push @rpn, $tmp;
	};
	return \@rpn;
}


1;
