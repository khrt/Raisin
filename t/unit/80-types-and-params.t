
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../lib";

use Raisin::Types;
use Raisin::Param;

my $int = Raisin::Types::Integer->new(\123);
is ref $int, 'Raisin::Types::Integer', 'Integer: OK';
$int = Raisin::Types::Integer->new(\1.23);
is $int, undef, 'Integer: FAILED';

my $float_value = 1.23;
my $float = Raisin::Types::Float->new(\$float_value);
is ref $float, 'Raisin::Types::Float', 'Float: OK';
$float = Raisin::Types::Float->new(\'string');
is $float, undef, 'Float: FAILED';
is $float_value, '1.2300', 'Float: in';

#required/optional => [name, type, default, regex]
my @types = (
    optional => ['sclr', 'Raisin::Types::Scalar'],
    optional => ['str', 'Raisin::Types::String', undef, qr/regex/],
    required => ['float', 'Raisin::Types::Float', 0, qr/^\d\.\d+$/],
    requires => ['int', 'Raisin::Types::Integer'],
);
my @values = (
    [[['array']], 'scalar'],
    [qw(invalid regex)],
    [12, '1.2000'],
    [qw(digit 123)]
);
my @keys = qw(named params);

my $index = 0;
while (my @param = splice @types, 0, 2) {
    my $required = $param[0] =~ /require(?:d|s)/ ? 1 : 0;
    my $options = $param[1];

    my $key = $keys[int(rand(1))];

    my $param = Raisin::Param->new(
        named => $key eq 'named' ? 1 : 0,
        param => \@param
    );
    isa_ok $param, 'Raisin::Param';

    is $param->default, $options->[2], 'default';
    is $param->name, $options->[0], 'name';
    is $param->named, $key eq 'named' ? 1 : 0, 'named';
    is $param->required, $required, 'required';
    is $param->type, $options->[1], 'type';

    my @expected = (undef, 1);
    for my $v (@{ $values[$index] }) {
        is $param->validate(\$v), shift @expected,
            $param->type->name . ': ' . $param->name . " [$v]";
    }
    $index++;
}

done_testing;
