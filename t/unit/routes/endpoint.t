
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use Types::Standard qw(Int);

use lib "$Bin/../../../lib";

use Raisin::Param;
use Raisin::Routes::Endpoint;

my @CASES = (
    {
        object => {
            api_format => 'json',
            desc => 'Test endpoint',
            method => 'POST',
            params => [
                Raisin::Param->new(
                    named => 1,
                    type => 'requires',
                    spec => { name => 'id', type => Int },
                ),
            ],
            path => '/api/user/:id',
        },
        input => { method => 'post', path => '/api/user/42.json' },
        expected => 1,
    },
    {
        object => {
            api_format => 'json',
            method => 'POST',
            path => '/api/user/:id',
        },
        input => { method => 'post', path => '/api/user/42' },
        expected => 1,
    },
    {
        object => {
            method => 'PUT',
            path => '/api/user/:id',
        },
        input => { method => 'put', path => '/api/user/42' },
        expected => 1,
    },
    {
        object => {
            method => 'GET',
            path => '/api/user/:id',
        },
        input => { method => 'get', path => '/api/user/42' },
        expected => 1,
    },

    {
        object => {
            api_format => 'json',
            method => 'POST',
            path => '/api/user/:id',
        },
        input => { method => 'post', path => '/api/user/42.yaml' },
        expected => undef,
    },
    {
        object => {
            method => 'POST',
            path => '/api/user/:id',
        },
        input => { method => 'put', path => '/api/user/42' },
        expected => undef,
    },
    {
        object => {
            method => 'PUT',
            path => '/api/user/:id',
        },
        input => { method => 'put', path => '/api/item/42' },
        expected => undef,
    },
);

sub _make_object {
    my $object = shift;
    Raisin::Routes::Endpoint->new(code => sub { $object->{method} }, %$object);
}

subtest 'accessors' => sub {
    for my $case (@CASES) {
        my $e = _make_object($case->{object});
        #isa_ok $e, 'Raisin::Routes::Endpoint', 'e';

        subtest '-' => sub {
            for my $m (keys %{ $case->{object} }) {
                is $e->$m, $case->{object}{$m}, $m;
            }
        };
    }
};

subtest 'match' => sub {
    for my $case (@CASES) {
        subtest "$case->{object}{method}:$case->{object}{path}" => sub {
            my $e = _make_object($case->{object});
            #isa_ok $e, 'Raisin::Routes::Endpoint', 'e';

            my $is_matched = $e->match($case->{input}{method}, $case->{input}{path});

            is $is_matched, $case->{expected}, 'match';

            # format
            if ($is_matched && ($case->{input}{path} =~ /\.(.+)$/msix)) {
                is $e->format, $1, 'format: ' . $1;
            }

            # named params
            if ($is_matched && @{ $e->params }) {
                for my $p (@{ $e->params }) {
                    ok $e->named->{$p->name}, 'named: ' . $p->name;
                }
            }
        };
    }
};

done_testing;
