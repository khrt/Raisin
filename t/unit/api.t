
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Raisin::API;
use Raisin::Entity::Object;
use Raisin::Routes;

sub _clean_app {
    my $app = Raisin::API->app;
    $app->{middleware} = {};
    $app->{mounted} = [];
    $app->{resource_desc} = {};
    $app->{routes} = Raisin::Routes->new;

    # TODO: clean namespace?
    delete $app->{loaded_plugins};

    delete $app->{api_format};
    delete $app->{api_default_format};
    delete $app->{api_version};
}

#subtest 'run' => sub {
#    plan skip_all => 'not implemented';
#    _clean_app();
#};

subtest 'mount' => sub {
    plan skip_all => 'not implemented';
};

subtest 'middleware' => sub {
    my $app = Raisin::API->app;

    middleware '+Plack::Middleware::ContentLength';
    is_deeply $app->{middleware},
        { '+Plack::Middleware::ContentLength' => [], }, 'added';

    my $psgi_app = run;
    is ref($psgi_app), 'CODE', 'run';

    is_deeply $app->{_loaded_middleware},
        { '+Plack::Middleware::ContentLength' => 1, }, 'loaded';

    _clean_app();
};

#subtest 'before' => sub {
#    plan skip_all => 'not implemented';
#};
#
#subtest 'before_validation' => sub {
#    plan skip_all => 'not implemented';
#};
#
#subtest 'after_validation' => sub {
#    plan skip_all => 'not implemented';
#};
#
#subtest 'after' => sub {
#    plan skip_all => 'not implemented';
#};

subtest 'resource' => sub {
    my ($level0, $level1, $level2, $level3);

    $level0 = resource l0 => sub {
        $level1 = resource l1 => sub {
            $level2 = resource l2 => sub {
                $level3 = del sub { 'del' };
                $level3 = get sub { 'get' };
                $level3 = head sub { 'head' };
                $level3 = options sub { 'options' };
                $level3 = patch sub { 'patch' };
                $level3 = post sub { 'post' };
                $level3 = put sub { 'put' };
            };
        };
    };

    is $level0, '/', 'level0';
    is $level1, '/l0', 'level1';
    is $level2, '/l0/l1', 'level2';
    is $level3, '/l0/l1/l2', 'level3';

    _clean_app();
};

subtest 'namespace' => sub {
    my $level0 = namespace nl0 => sub {};
    is $level0, '/', 'level0';
};

subtest 'route_param' => sub {
    my ($level0, $level1);

    $level0 = route_param id => sub {
        $level1 = get sub { 'api' };
    };

    is $level0, '/', 'level0';
    is $level1, '/:id', 'level1';

    # TODO: named

    _clean_app();
};

subtest 'HTTP verbs' => sub {
    resource api => sub {
        get sub { 'get' };
        post sub { 'post' };

        route_param id => sub {
            put sub { 'put' };
            del sub { 'del' };
        };
    };

    my $app = Raisin::API->app;
    my $routes = $app->routes;

    ok $routes->list->{'/api'}{GET}, 'GET';
    ok $routes->list->{'/api'}{POST}, 'POST';

    ok $routes->list->{'/api/:id'}{PUT}, 'PUT';
    ok $routes->list->{'/api/:id'}{DELETE}, 'DELETE';

    _clean_app();
};

subtest 'desc' => sub {
    desc 'for resource';
    resource api => sub {
        desc 'for route_param';
        route_param id => sub {
            desc 'for verb';
            get sub { 'api' };
        };
    };

    my $app = Raisin::API->app;

    is $app->resource_desc('api'), 'for resource', 'resource';
    is $app->resource_desc(':id'), 'for route_param', 'route_param';

    my $r = $app->routes->routes->[0];
    is $r->desc, 'for verb', 'verb';

    _clean_app();
};

subtest 'produces' => sub {
   my $produces = ['image/png'];
    desc 'for produce';
    produces  $produces;
    resource api => sub {
        desc 'for route_param';
        route_param id => sub {
            desc 'for verb';
            get sub { 'api' };
        };
    };

    my $app = Raisin::API->app;


    my $r = $app->routes->routes->[0];
    is_deeply $r->produces, $produces, 'produces';

    _clean_app();
};

subtest 'params' => sub {
    resource api => sub {
        params requires => { name => 'id', type => undef };
        route_param id => sub {
            params(
                requires => { name => 'start', type => undef },
                optional => { name => 'count', type => undef },
            );
            get sub { param };
        }
    };

    my $app = Raisin::API->app;
    my $e = $app->routes->routes->[0];

    my %params = map { $_->name => $_ } @{ $e->params };

    ok $params{id}, 'id';
    is $params{id}->named, 1, 'named';
    is $params{id}->required, 1, 'required';

    ok $params{start}, 'start';
    is $params{start}->named, 0, 'named';
    is $params{start}->required, 1, 'required';

    ok $params{count}, 'count';
    is $params{count}->named, 0, 'named';
    is $params{count}->required, 0, 'optional';

    _clean_app();
};

subtest 'req' => sub {
    is req, undef, 'empty req';
};

subtest 'res' => sub {
    is res, undef, 'empty res';
};

#subtest 'param' => sub {};
#subtest 'include_missing' => sub {};
#subtest 'session' => sub {};

subtest 'present' => sub {
    my $app = Raisin::API->app;

    my %data_hash = (
        key0 => 'value0',
        key1 => 'value1',
    );

    $app->res(Plack::Response->new);
    present data => \%data_hash;
    is_deeply $app->res->body, { data => \%data_hash }, 'Data';

    {
        no strict 'refs';
        no warnings 'once';
        @Raisin::API::Entity::Test::EXPOSE = (
            Raisin::Entity::Object->new('key0', as => 'key')
        );
    }

    $app->res(Plack::Response->new);
    present data => \%data_hash, with => 'Raisin::API::Entity::Test';
    is_deeply $app->res->body, { data => { key => 'value0' } }, 'Data w/ Entity';

    _clean_app();
};

subtest 'plugin' => sub {
    my $app = Raisin::API->app;

    plugin 'Swagger';
    is ref($app->{loaded_plugins}{Swagger}), 'Raisin::Plugin::Swagger', 'load';
    ok $app->can('swagger_build_spec'), 'export';

    _clean_app();
};

subtest 'api_default_format' => sub {
    is api_default_format('json'), 'json', 'set';
    is api_default_format(), 'json', 'get';

    _clean_app();
};

subtest 'api_format' => sub {
    is api_format('json'), 'json', 'set';

    is api_format(), 'json', 'get';
    is api_default_format(), 'json', 'get default format';

    _clean_app();
};

subtest 'api_version' => sub {
    is api_version('1.42'), '1.42', 'set';
    is api_version(), '1.42', 'get';

    _clean_app();
};

subtest 'error' => sub {
    error(501, 'Unit test!');

    my $res = Raisin::API->app->res;
    is $res->status, 501, 'status';
    is $res->body, 'Unit test!', 'body';

    _clean_app();
};

subtest 'resource_bad' => sub {
    throws_ok {
         resource l0 => sub {
              resource l1a => sub {}, # should be semicolon, not comma!
              resource l1b => sub {};
         };
    } qr/missing a semicolon/, "Bad comma caught";
    _clean_app();
};

subtest 'params nested route_param' => sub {
    resource api => sub {
        params requires => { name => 'id', type => undef };
        route_param id => sub {
            get sub { param };

            params requires => { name => 'sub_id', type => undef };
            route_param sub_id => sub {
                get sub { param };
            };
        }
    };

    my $app = Raisin::API->app;
    my $e = $app->routes->routes->[1];

    my %params = map { $_->name => $_ } @{ $e->params };

    ok $params{id}, 'id';
    is $params{id}->named, 1, 'named';
    is $params{id}->required, 1, 'required';

    ok $params{sub_id}, 'sub_id';
    is $params{sub_id}->named, 1, 'named';
    is $params{sub_id}->required, 1, 'required';

    _clean_app();
};

done_testing;
