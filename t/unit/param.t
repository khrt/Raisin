
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Param;
use Types::Standard qw(ScalarRef Any Num Str Int);

my $QUIET = 1;

my @CASES = (
    {
        test => {
            required => 0,
            data => { name => 'str', type => Str, default => 'def', regex => qr/match/ },
        },
        input => 'match',
        expected => 1,
    },
    {
        test => {
            required => 0,
            data => { name => 'str', type => Str, default => 'def', regex => qr/match/ },
        },
        input => 'not much',
        expected => undef,
    },
    {
        test => {
            required => 0,
            data => { name => 'str', type => Str, default => 'def', regex  => qr/match/ },
        },
        input => 42,
        expected => undef,
    },

    {
        test => {
            required => 1,
            data => { name => 'float', type => Num, regex => qr/^\d\.\d+$/ },
        },
        input => 3.14,
        expected => 1,
    },
    {
        test => {
            required => 1,
            data => { name => 'float', type => Num, regex => qr/^\d\.\d+$/ },
        },
        input => 314,
        expected => undef,
    },
    {
        test => {
            required => 1,
            data => { name => 'float', type => Num, regex => qr/^\d\.\d+$/ },
        },
        input => 'string',
        expected => undef,
    },

    {
        test => {
            required => 1,
            data => { name => 'int', type => Int },
        },
        input => 42,
        expected => 1,
    },
    {
        test => {
            required => 1,
            data => { name => 'int', type => Int },
        },
        input => 4.2,
        expected => undef,
    },
    {
        test => {
            required => 1,
            data => { name => 'int', type => Int },
        },
        input => 'string',
        expected => undef,
    },
);

sub _make_object {
    my $test = shift;
    Raisin::Param->new(
        named => int(rand(1)),
        type  => $test->{required} ? 'required' : 'optional',
        spec  => $test->{data},
    );
}

sub _make_name {
    my $case = shift;
    uc($case->{test}{data}{name}) . " " . $case->{input};
}

subtest 'parse, +accessors' => sub {
    for my $case (@CASES) {
        my $name = _make_name($case);

        my $param = _make_object($case->{test});
        isa_ok $param, 'Raisin::Param', $name;

        is $param->default, $case->{test}{data}{default}, 'is default match';
        is $param->name, $case->{test}{data}{name}, 'is name match';
        is $param->named, 0, 'is named';
        is $param->required, $case->{test}{required}, 'is required';
        is $param->type, $case->{test}{data}{type}, 'is type match';
    }
};

subtest 'validate' => sub {
    for my $case (@CASES) {
        my $name = _make_name($case);

        my $param = _make_object($case->{test});
        isa_ok $param, 'Raisin::Param', $name;

        my $test = $case->{input};
        is $param->validate(\$test, $QUIET), $case->{expected}, "validate: $case->{input}";
    }
};

done_testing;
