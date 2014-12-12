
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use YAML 'Load';

use lib "$Bin/../../lib";

subtest 'run' => sub {
    plan skip_all => 'not implemented';
};

subtest 'mount' => sub {
    plan skip_all => 'not implemented';
};

subtest 'middleware' => sub {
    plan skip_all => 'not implemented';

};

subtest 'before' => sub {
    plan skip_all => 'not implemented';

};

subtest 'before_validation' => sub {
    plan skip_all => 'not implemented';

};

subtest 'after_validation' => sub {
    plan skip_all => 'not implemented';

};

subtest 'after' => sub {
    plan skip_all => 'not implemented';

};

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
            params(requires => { name => 'id', type => Int });
            route_param id => sub {
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

subtest 'HTTP verbs' => sub {
    plan skip_all => 'not implemented';

};

subtest 'desc' => sub {
    plan skip_all => 'not implemented';

};

subtest 'params' => sub {
    my $app = eval {
        use Raisin::API;
        use Types::Standard qw(Int);

        resource api => sub {
            params(
                requires => { name => 'foo', type => Int },
                optional => { name => 'bar', type => Int },
            );
            put sub { shift };
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
                desc 'GET action';
                get sub { 'get action' };

                desc 'GET `all` action';
                get 'all' => sub { 'get all action' };

                params(requires => { name => 'id', type => Int });
                route_param id => sub {
                    desc 'Nested GET action';
                    params(optional => { name => 'do', type => Int });
                    get sub { 'nested get action' };

                    desc 'Nested GET `all` action';
                    params(optional => { name => 'do', type => Int });
                    get 'all' => sub { 'nested get all action' };
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
                params(optional => { name => 'do', type => Int });
                get sub { 'get action' };

                params(optional => { name => 'do', type => Int });
                get 'all' => sub { 'get all action' };

                params(requires => { name => 'id', type => Int });
                route_param id => sub {
                    desc 'Nested GET action';
                    params(optional => { name => 'do', type => Int });
                    get sub { 'nested get action' };

                    desc 'Nested GET `all` action';
                    params(optional => { name => 'do', type => Int });
                    get 'all' => sub { 'nested get all action' };
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

subtest 'session' => sub {
    plan skip_all => 'not implemented';

};

subtest 'present' => sub {
    my %item0 = (id => 1, name => 'Bruce Wayne');
    my %item1 = (id => 2, name => 'Batman');
    my @data = (\%item0, \%item1);

    my $hash_func = sub {
        my $person = shift;
        my $hash = 0;
        for (split //, $person->{name}) {
            $hash = $hash * ord($_) + 42;
        }
        $hash;
    };

    my @data_with_entity = (
        { %item0, hash => $hash_func->(\%item0), },
        { %item1, hash => $hash_func->(\%item1), },
    );

    my $app = eval {
        package PersonEntity;
        use Raisin::Entity;
        expose 'id';
        expose 'name';
        expose 'hash', $hash_func;

        package main;
        use Raisin::API;
        resource 'present' => sub {
            get sub {
                present data => \@data;
                present data_with => \@data, with => 'PersonEntity';
                present size => scalar @data;
            };
        };
        run;
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/present');
        my $content = Load($res->content);
        is_deeply $content, {
            data => \@data,
            data_with => \@data_with_entity,
            size => scalar @data,
        };
    };
};

subtest 'plugin' => sub {
    plan skip_all => 'not implemented';

};

subtest 'api_default_format' => sub {
    plan skip_all => 'not implemented';

};

subtest 'api_format' => sub {
    plan skip_all => 'not implemented';

};

subtest 'api_version' => sub {
    plan skip_all => 'not implemented';

};

subtest 'error' => sub {
    plan skip_all => 'not implemented';

};

done_testing;
