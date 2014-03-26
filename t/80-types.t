
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
    required => ['newint', $Raisin::Types::Integer, 0, qr/digit/],
    requires => ['int', $Raisin::Types::Integer],
);
my @keys = qw(named params);

while (my @param = splice @types, 0, 2) {
    my $required = $param[0] =~ /require(?:d|s)/ ? 1 : 0;
    my $options = $param[1];

    my $key = $keys[int(rand(1))];

    my $param = Raisin::Param->new(
        named => $key eq 'named' ? 1 : 0,
        param => \@param
    );
    isa_ok $param, 'Raisin::Param';

    is $param->required, $required, 'required';
    is $param->named, $key eq 'named' ? 1 : 0, 'named';
    is $param->name, $options->[0], 'name';
    is $param->type, $options->[1], 'type';
    is $param->default, $options->[2], 'default';
    is $param->regex, $options->[3], 'regex';
}

done_testing;
