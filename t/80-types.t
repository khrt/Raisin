
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../lib";

use Raisin::Types;
use Raisin::Param;

#required/optional => [name, type, default, regex]
my @types = (
    optional => ['str', $Raisin::Types::String, undef, qr/regex/],
    required => ['float', $Raisin::Types::Float, 0, qr/^\d\.\d$/],
    requires => ['int', $Raisin::Types::Integer],
);
my @values = (
    [qw(invalid regex)],
    [qw(12 1.2)],
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
    is $param->regex, $options->[3], 'regex';
    is $param->required, $required, 'required';
    is $param->type, $options->[1], 'type';

    my @validate_res = (undef, 1);
    for my $v (@{ $values[$index] }) {
        is $param->validate(\$v), shift @validate_res, $param->name;
    }
    $index++;
}

done_testing;
