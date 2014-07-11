
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Plack::Util;
use Test::More;

use lib "$Bin/../../lib";

my $app = eval {
    use Raisin::API;
    use Types::Standard qw(Int);

    resource 'test' => sub {
        get sub { 'Level 1' };
        resource 'subtest' => sub {
            get sub { 'Level 2' };
            resource 'subsubtest' => sub {
                get sub { 'Level 3' };
            };
        };

        route_param 'id' => Int, sub {
            get sub { 'Level 1' };
            route_param 'subid' => Int, sub {
                get sub { 'Level 2' };
                route_param 'subsubid' => Int, sub {
                    get sub { 'Level 3' };
                };
            };
        };
    };

    run;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res;

    subtest 'netsted route params' => sub {
        $res = $cb->(GET '/test/1');
        is($res->content, 'Level 1', 'Level 1');

        $res = $cb->(GET '/test/1/2');
        is($res->content, 'Level 2', 'Level 2');

        $res = $cb->(GET '/test/1/2/3');
        is($res->content, 'Level 3', 'Level 3');
    };

    subtest 'nested resouces' => sub {
        $res = $cb->(GET '/test');
        is($res->content, 'Level 1', 'Level 1');

        $res = $cb->(GET '/test/subtest');
        is($res->content, 'Level 2', 'Level 2');

        $res = $cb->(GET '/test/subtest/subsubtest');
        is($res->content, 'Level 3', 'Level 3');
    };
};

done_testing;
