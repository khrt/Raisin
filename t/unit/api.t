
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use YAML 'Load';

use lib "$Bin/../../lib";

#subtest 'resource' => sub {
#    my $app = eval {
#        use Raisin::API;
#        use Types::Standard qw(Int);
#
#        resource api => sub { get sub { 'api/get' } };
#        run;
#    };
#
#    test_psgi $app, sub {
#        my $cb = shift;
#        my $res = $cb->(GET '/api');
#
#        subtest 'GET /api' => sub {
#            is $res->code, 200;
#            is $res->content, 'api/get';
#        };
#    };
#};
#
#subtest 'route_param' => sub {
#    my $app = eval {
#        use Raisin::API;
#        use Types::Standard qw(Int);
#
#        resource api => sub {
#            route_param id => Int,
#            sub {
#                get sub {
#                    my $params = shift;
#                    "api/$params->{id}/get"
#                }
#            }
#        };
#        run;
#    };
#
#    test_psgi $app, sub {
#        my $cb = shift;
#        my $res = $cb->(GET '/api/1');
#
#        subtest 'GET /api/1' => sub {
#            is $res->code, 200;
#            is $res->content, 'api/1/get';
#        };
#    };
#
#    test_psgi $app, sub {
#        my $cb = shift;
#        my $res = $cb->(GET '/api/string');
#
#        subtest 'GET /api/string' => sub {
#            is $res->code, 404;
#        };
#    };
#};
#
#subtest 'params' => sub {
#    my $app = eval {
#        use Raisin::API;
#        use Types::Standard qw(Int);
#
#        resource api => sub {
#            params [
#                requires => ['foo', Int],
#                optional => ['bar', Int],
#            ],
#            put => sub { shift };
#        };
#        run;
#    };
#
#    test_psgi $app, sub {
#        my $cb = shift;
#        my $res = $cb->(PUT '/api?foo=1&bar=2');
#
#        subtest 'PUT /api' => sub {
#            is $res->code, 200;
#            is_deeply Load($res->content), { foo => 1, bar => 2 };
#        };
#    };
#};

subtest 'new route' => sub {

    # desc ?
    # params ?
    # get ? ?

    # desc 'new', params => [...], get => 'all' => sub {...};
    # desc 'new', params => [...], get => sub {...};
    # desc 'new', get => 'all' => sub {...};
    # desc 'new', get => sub {...};
    #
    # params => [...], desc => 'new', get => 'all' => sub {...};
    # params => [...], desc => 'new', get => sub {...};
    # params => [...], get => 'all' => sub {...};
    # params => [...], get => sub {...};

    subtest 'desc' => sub {

    };




    my $app = eval {
        use Raisin::API;
        use Types::Standard qw(Int);

        resource api => sub {
            params [
                requires => ['foo', Int],
                optional => ['bar', Int],
            ],
            put => sub { shift };
        };
        run;
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(PUT '/api?foo=1&bar=2');

        subtest 'PUT /api' => sub {
            is $res->code, 200;
            is_deeply Load($res->content), { foo => 1, bar => 2 };
        };
    };
};

done_testing;
