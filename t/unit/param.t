
use strict;
use warnings;

use Test::More;

use Raisin::Param;
use Types::Standard qw(Split ArrayRef ScalarRef HashRef Any Num Str Int);

my $QUIET = 1;

my @CASES = (
    {
        test => {
            required => 0,
            data => { name => 'abc', type => ArrayRef->plus_coercions(Split[qr{,}]) },
        },
        input => "a,b,c",
        expected => 1,
    },

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
            data => { name => 'str', type => Str, default => 'def', regex => qr/match/ },
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

    # Nested
    {
        test => {
            required => 1,
            data => {
                name => 'person',
                type => HashRef,
                encloses => [
                    requires => {
                        name => 'name', type => HashRef, encloses => [
                            requires => { name => 'first_name', type => Str },
                            requires => { name => 'last_name', type => Str }
                        ],
                    },
                    optional => { name => 'city', type => Str },
                    optional => { name => 'postcode', type => Int },
                ],
            },
        },
        input => {
            name => {
                first_name => 'Bruce',
                last_name => 'Wayne',
            },
            city => 'Gotham City',
        },
        expected => 1,
    },
    {
        test => {
            required => 1,
            data => {
                name => 'person',
                type => HashRef,
                encloses => [
                    requires => {
                        name => 'name', type => HashRef, encloses => [
                            requires => { name => 'first_name', type => Str },
                            requires => { name => 'last_name', type => Str }
                        ],
                    },
                    optional => { name => 'city', type => Str },
                    optional => { name => 'postcode', type => Int },
                ],
            },
        },
        input => {
            name => 'Bruce Wayne',
            city => 'Gotham City',
        },
        expected => undef,
    },

    {
        test => {
            required => 1,
            data => {
                name => 'person',
                type => HashRef,
                encloses => [
                    requires => {
                        name => 'name', type => Str, encloses => [
                            requires => { name => 'first_name', type => Str },
                            requires => { name => 'last_name', type => Str }
                        ],
                    },
                    optional => { name => 'city', type => Str },
                    optional => { name => 'postcode', type => Int },
                ],
            },
        },
        input => {
            name => 'Bruce Wayne',
            city => 'Gotham City',
        },
        expected => 1,
    },

    {
        test => {
            required => 1,
            data => {
                name => 'lvl0',
                type => HashRef,
                encloses => [
                    requires => {
                        name => 'lvl1', type => HashRef, encloses => [
                            requires => {
                                name => 'lvl2', type => HashRef, encloses => [
                                    requires => { name => 'lvl3', type => Str },
                                ],
                            },
                        ],
                    },
                ],
            },
        },
        input => { lvl1 => { lvl2 => { lvl3 => 'value', }, }, },
        expected => 1,
    },
    {
        test => {
            required => 1,
            data => {
                name => 'lvl0',
                type => HashRef,
                encloses => [
                    requires => {
                        name => 'lvl1', type => HashRef, encloses => [
                            requires => {
                                name => 'lvl2', type => HashRef, encloses => [
                                    requires => { name => 'lvl3', type => Str },
                                ],
                            },
                        ],
                    },
                ],
            },
        },
        input => { lvl1 => { lvl2 => { }, }, },
        expected => undef,
    },

    {
        test => {
            required => 1,
            data => {
                name => 'user',
                type => HashRef,
                encloses => [
                    requires => { name => 'first_name', type => Str, desc => 'First name' },
                    requires => { name => 'last_name', type => Str, desc => 'Last name' },
                    requires => { name => 'password', type => Str, desc => 'User password' },
                    optional => { name => 'email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email' },
                ]
            },
        },
        input => {
            first_name => 'Bruce',
            last_name => 'Wayne',
            password => 'qwerty',
            email => 'joe@doe.com',
        },
        expected => 1,
    },
);

{
    no strict 'refs';
    *Raisin::log = sub { note(sprintf $_[1], @_[2 .. $#_]) };
}

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

        subtest $name => sub {
            my $param = _make_object($case->{test});
            isa_ok $param, 'Raisin::Param', 'param';

            is $param->default, $case->{test}{data}{default}, 'default';
            is $param->name, $case->{test}{data}{name}, 'name';
            is $param->named, 0, 'named';
            is $param->required, $case->{test}{required}, 'required';
            is $param->type, $case->{test}{data}{type}, 'type';
        };
    }
};

subtest 'parse, +in' => sub {
    my @IN_CASES = (
        {
            test => {
                required => 1,
                data => { name => 'broken', type => Int, in => 'broken' },
            },
            input => 'dummy',
            expected => undef,
        },
        map {
            {
                test => {
                    required => 1,
                    data => { name => $_, type => Int, in => $_ },
                },
                input => 'dummy',
                expected => 1,
            }
        } qw/path formData body header query/,
    );

    for my $case (@IN_CASES) {
        my $name = _make_name($case);

        subtest $name => sub {
            my $param = _make_object($case->{test});

            if ($case->{expected}) {
                isa_ok $param, 'Raisin::Param', 'param';
                is $param->in, $case->{test}{data}{in};
            }
            else {
                is $param, undef;
            }
        };
    }
};

subtest 'validate' => sub {
    for my $case (@CASES) {
        my $name = _make_name($case);

        subtest $name => sub {
            my $param = _make_object($case->{test});
            isa_ok $param, 'Raisin::Param', 'param';

            my $test = $case->{input};
            is $param->validate(\$test, $QUIET&0), $case->{expected}, "validate: $case->{input}";
        };
    }
};

done_testing;
