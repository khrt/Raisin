
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use YAML 'Load';

use lib "$Bin/../../lib";

subtest 'resource' => sub {
    my $app = eval {
        use Raisin::API;
        use Types::Standard qw(Int);

        resource api => sub { get sub { 'api/get' } };
        run;
    };

    test_psgi $app, sub {
        my $cb = shift;

        subtest 'GET /api' => sub {
            my $res = $cb->(GET '/api');
            is $res->code, 200;
            is $res->content, 'api/get';
        };
    };
};

subtest 'route_param' => sub {
    my $app = eval {
        use Raisin::API;
        use Types::Standard qw(Int);

        resource api => sub {
            route_param id => Int,
            sub {
                get sub {
                    my $params = shift;
                    "api/$params->{id}/get"
                }
            }
        };
        run;
    };

    test_psgi $app, sub {
        my $cb = shift;

        subtest 'GET /api/1' => sub {
            my $res = $cb->(GET '/api/1');
            is $res->code, 200;
            is $res->content, 'api/1/get';
        };
    };

    test_psgi $app, sub {
        my $cb = shift;

        subtest 'GET /api/string' => sub {
            my $res = $cb->(GET '/api/string');
            is $res->code, 404;
        };
    };
};

subtest 'params' => sub {
    my $app = eval {
        use Raisin::API;
        use Types::Standard qw(Int);

        resource api => sub {
            params [
                requires => { name => 'foo', type => Int },
                optional => { name => 'bar', type => Int },
            ],
            put => sub { shift };
        };
        run;
    };

    test_psgi $app, sub {
        my $cb = shift;

        subtest 'PUT /api' => sub {
            my $res = $cb->(PUT '/api?foo=1&bar=2');
            is $res->code, 200;
            is_deeply Load($res->content), { foo => 1, bar => 2 };
        };
    };
};

subtest 'new route' => sub {
    subtest 'desc' => sub {
        # desc 'new', get => sub {...};
        # desc 'new', get => 'all' => sub {...};
        # desc 'new', params => [...], get => sub {...};
        # desc 'new', params => [...], get => 'all' => sub {...};

        my $app = eval {
            use Raisin::API;
            use Types::Standard qw(Int);

            resource desc => sub {
                desc 'GET action',
                get => sub { 'get action' };

                desc 'GET `all` action',
                get => 'all' => sub { 'get all action' };

                route_param id => Int,
                sub {
                    desc 'Nested GET action',
                    params => [optional => { name => 'do', type => Int }],
                    get => sub { 'nested get action' };

                    desc 'Nested GET `all` action',
                    params => [optional => { name => 'do', type => Int }],
                    get => 'all' => sub { 'nested get all action' };
                };
            };
            run;
        };

        test_psgi $app, sub {
            my $cb = shift;

            subtest 'desc -> http verb' => sub {
                my $res = $cb->(GET '/desc');
                is $res->code, 200;
                is $res->content, 'get action';
            };

            subtest 'desc -> http verb -> path' => sub {
                my $res = $cb->(GET '/desc/all');
                is $res->code, 200;
                is $res->content, 'get all action';
            };

            subtest 'desc -> params -> http verb' => sub {
                my $res = $cb->(GET '/desc/1');
                is $res->code, 200;
                is $res->content, 'nested get action';
            };

            subtest 'desc -> params -> http verb -> path' => sub {
                my $res = $cb->(GET '/desc/1/all');
                is $res->code, 200;
                is $res->content, 'nested get all action';
            };
        };
    };

    subtest 'params' => sub {
        # params => [...], get => sub {...};
        # params => [...], get => 'all' => sub {...};
        # params => [...], desc => 'new', get => sub {...};
        # params => [...], desc => 'new', get => 'all' => sub {...};

        my $app = eval {
            use Raisin::API;
            use Types::Standard qw(Int);

            resource params => sub {
                params [optional => { name => 'do', type => Int }],
                get => sub { 'get action' };

                params [optional => { name => 'do', type => Int }],
                get => 'all' => sub { 'get all action' };

                route_param id => Int,
                sub {
                    params [optional => { name => 'do', type => Int }],
                    desc => 'Nested GET action',
                    get => sub { 'nested get action' };

                    params [optional => { name => 'do', type => Int }],
                    desc => 'Nested GET `all` action',
                    get => 'all' => sub { 'nested get all action' };
                };
            };
            run;
        };

        test_psgi $app, sub {
            my $cb = shift;

            subtest 'params -> http verb' => sub {
                my $res = $cb->(GET '/params');
                is $res->code, 200;
                is $res->content, 'get action';
            };

            subtest 'params -> http verb -> path' => sub {
                my $res = $cb->(GET '/params/all');
                is $res->code, 200;
                is $res->content, 'get all action';
            };

            subtest 'params -> desc -> http verb' => sub {
                my $res = $cb->(GET '/params/1');
                is $res->code, 200;
                is $res->content, 'nested get action';
            };

            subtest 'params -> desc -> http verb -> path' => sub {
                my $res = $cb->(GET '/params/1/all');
                is $res->code, 200;
                is $res->content, 'nested get all action';
            };
        };
    };

    subtest 'http verb' => sub {
        # get => sub {...};
        # get => 'all' => sub {...};

        my $app = eval {
            use Raisin::API;
            use Types::Standard qw(Int);

            resource http_verb => sub {
                get sub { 'get action' };
                get 'all' => sub { 'get all action' };
            };
            run;
        };

        test_psgi $app, sub {
            my $cb = shift;

            subtest 'http verb' => sub {
                my $res = $cb->(GET '/http_verb');
                is $res->code, 200;
                is $res->content, 'get action';
            };

            subtest 'http verb -> path' => sub {
                my $res = $cb->(GET '/http_verb/all');
                is $res->code, 200;
                is $res->content, 'get all action';
            };
        };
    };
};

done_testing;
