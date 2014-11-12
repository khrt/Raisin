
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Param;
use Types::Standard qw(ScalarRef Any Num Str Int);

my @types = (
    optional => { name => 'str', type => Str, default => undef, regex => qr/regex/ },
    required => { name => 'float', type => Num, default => 0, regex => qr/^\d\.\d+$/ },
    requires => { name => 'int', type => Int },
);
my @values = (
    [qw(invalid regex)],
    [12, '1.2000'],
    [qw(digit 123)]
);
my @keys = qw(named params);

my $index = 0;
while (my @param = splice @types, 0, 2) {
    my $required = $param[0] =~ /require(?:d|s)/ ? 1 : 0;
    my $spec = $param[1];

    my $key = $keys[int(rand(1))];

    my $param = Raisin::Param->new(
        named => $key eq 'named' ? 1 : 0,
        type => $param[0],
        spec => $param[1],
    );
    isa_ok $param, 'Raisin::Param';

    is $param->default, $spec->{default}, 'default';
    is $param->name, $spec->{name}, 'name';
    is $param->named, $key eq 'named' ? 1 : 0, 'named';
    is $param->required, $required, 'required';
    is $param->type, $spec->{type}, 'type';

    my @expected = (undef, 1);
    for my $v (@{ $values[$index] }) {
        is $param->validate(\$v), shift @expected, "validate $v: ${\$param->type->name}";
    }
    $index++;
}

done_testing;
