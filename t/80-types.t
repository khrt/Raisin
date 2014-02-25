### NOTE Useless test

use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../lib";

use Raisin::Types;
use Raisin::Param;

#required/optional => [name, type, default, regex]
my @types = (
    required => ['newint', $Raisin::Types::Integer, 0, qr/digit/],
    required => ['int', $Raisin::Types::Integer],
    optional => ['str', $Raisin::Types::String, undef, qr/regex/],
);
#note explain @types;
my @keys = qw(named params);

for (my $i = 0; $i < scalar @types; $i += 2) {
    my ($type, $options) = ($types[$i], $types[$i+1]);
    my $key = $keys[int(rand(1))];

    my $param = Raisin::Param->new($key, $type, $options);
    isa_ok $param, 'Raisin::Param';

    is $param->required, $type eq 'required' ? 1 : 0, 'required';
    is $param->named, $key eq 'named' ? 1 : 0, 'named';
    is $param->name, $options->[0], 'name';
    is $param->type, $options->[1], 'type';
    is $param->default, $options->[2], 'default';
    is $param->regex, $options->[3], 'regex';
}

done_testing;
