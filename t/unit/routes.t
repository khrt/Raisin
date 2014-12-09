
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use Types::Standard qw(Int);

use lib "$Bin/../../lib";

use Raisin::Routes;

my @CASES = (
    {
        object => {
            api_format => 'json',
            desc => 'Test endpoint',
            method => 'POST',
            named => [requires => { name => 'id', type => Int },],
            params => [requires => { name => 'count', type => Int },],
            path => '/api/user/:id',
        },
        input => { method => 'post', path => '/api/user/42.json' },
        expected => 1,
    },
    {
        object => {
            api_format => 'json',
            method => 'PUT',
            path => '/api/item/:id',
        },
        input => { method => 'put', path => '/api/item/42' },
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
            method => 'PUT',
            path => '/api/user/:id',
        },
        input => { method => 'put', path => '/api/item/42' },
        expected => undef,
    },
);

subtest 'add' => sub {
    for my $case (@CASES) {
        my $r = Raisin::Routes->new;
        isa_ok $r, 'Raisin::Routes', 'r';

        is_deeply $r->cache, {}, 'Cache should be empty';
        is_deeply $r->list, {}, 'List should be empty';
        is_deeply $r->routes, [], 'Routes should be empty';

        my $res = $r->add(
            code => sub { $case->{object}{method} }, %{ $case->{object} }
        );

        ok $res, "Add: $case->{object}{method} $case->{object}{path}";

        is_deeply $r->cache, {}, 'Cache should be empty';

        ok $r->list->{ $case->{object}{method} }{ $case->{object}{path} },
            "List: $case->{object}{method} $case->{object}{path}";

        my $e = $r->routes->[-1];
        is $e->method, $case->{object}{method}, 'Routes: method';
        is $e->path, $case->{object}{path}, 'Routes: path';
    }
};

subtest 'find' => sub {
    for my $case (@CASES) {
        my $r = Raisin::Routes->new;
        isa_ok $r, 'Raisin::Routes', 'r';

        is_deeply $r->cache, {}, 'Cache should be empty';
        is_deeply $r->list, {}, 'List should be empty';
        is_deeply $r->routes, [], 'Routes should be empty';

        my $cache_key = lc "$case->{input}{method}:$case->{input}{path}";

        my $res = $r->add(
            code => sub { $case->{object}{method} }, %{ $case->{object} }
        );
        ok $res, "Add: $cache_key";

        my $e;
        subtest 'find' => sub {
            $e = $r->find($case->{input}{method}, $case->{input}{path});

            my $expected;
            if ($case->{expected}) {
                $expected = $e;
            }
            else {
                $expected = undef;
            }

            is_deeply $e, $expected, "Find: $cache_key";

            if ($e) {
                is $e->method, $case->{object}{method}, 'Method: ' . $e->method;
                is $e->path, $case->{object}{path}, 'Path: ' . $e->path;
            }
        };

        my $cache = $r->cache;
        is_deeply $cache->{$cache_key}[0], $e, "Cache: $cache_key";

        ok $r->list->{ $case->{object}{method} }{ $case->{object}{path} },
            "List: $case->{object}{method} $case->{object}{path}";

        subtest 'routes' => sub {
            my $er = $r->routes->[-1];
            is $er->method, $case->{object}{method}, 'Routes: method';
            is $er->path, $case->{object}{path}, 'Routes: path';
        };
    }
};

done_testing;
