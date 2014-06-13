
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Plack::Util;
use Test::More;

use YAML;
use JSON;

use lib "$Bin/../../lib";

my %PARAMS = (
    param0 => 0,
    param1 => 1,
    param2 => 'value1',
    param3 => ['value2.0', 'value2.1'],
);

my $json_app = eval {
    use Raisin::API;
    use Types::Standard qw(Int);

    route_param 'id' => Int, sub {
        get sub { 'Level 1' };
        route_param 'subid' => Int, sub {
            get sub { 'Level 2' };
            route_param 'subsubid' => Int, sub {
                get sub { 'Level 3' };
            };
        };
    };

    run;
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $res = $cb->(GET '/1');
    is($res->content, 'Level 1', 'Level 1');
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $res = $cb->(GET '/1/2');
    is($res->content, 'Level 2', 'Level 2');
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $res = $cb->(GET '/1/2/3');
    is($res->content, 'Level 3', 'Level 3');
};

done_testing;
