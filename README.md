# NAME

Raisin - a REST API micro framework for Perl.

# SYNOPSIS

    use strict;
    use warnings;

    use utf8;

    use Raisin::API;
    use Types::Standard qw(Any Int Str);

    my %USERS = (
        1 => {
            name => 'Darth Wader',
            password => 'deathstar',
            email => 'darth@deathstar.com',
        },
        2 => {
            name => 'Luke Skywalker',
            password => 'qwerty',
            email => 'l.skywalker@jedi.com',
        },
    );

    plugin 'Swagger', enable => 'CORS';
    api_format 'json';

    swagger_setup(
        title => 'A POD synopsis API',
        description => 'An example of API documentation.',
        #terms_of_service => '',

        contact => {
            name => 'Artur Khabibullin',
            url => 'http://github.com/khrt',
            email => 'rtkh@cpan.org',
        },

        license => {
            name => 'Perl license',
            url => 'http://dev.perl.org/licenses/',
        },
    );

    desc 'Users API';
    resource users => sub {
        summary 'List users';
        params(
            optional => { name => 'start', type => Int, default => 0, desc => 'Pager (start)' },
            optional => { name => 'count', type => Int, default => 10, desc => 'Pager (count)' },
        );
        get sub {
            my $params = shift;

            my @users
                = map { { id => $_, %{ $USERS{$_} } } }
                  sort { $a <=> $b } keys %USERS;

            my $max_count = scalar(@users) - 1;
            my $start = $params->{start} > $max_count ? $max_count : $params->{start};
            my $count = $params->{count} > $max_count ? $max_count : $params->{count};

            my @slice = @users[$start .. $count];
            { data => \@slice }
        };

        summary 'List all users at once';
        get 'all' => sub {
            my @users
                = map { { id => $_, %{ $USERS{$_} } } }
                  sort { $a <=> $b } keys %USERS;
            { data => \@users }
        };

        summary 'Create new user';
        params(
            requires => { name => 'name', type => Str, desc => 'User name' },
            requires => { name => 'password', type => Str, desc => 'User password' },
            optional => { name => 'email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email' },
        );
        post sub {
            my $params = shift;

            my $id = max(keys %USERS) + 1;
            $USERS{$id} = $params;

            { success => 1 }
        };

        desc 'Actions on the user';
        params requires => { name => 'id', type => Int, desc => 'User ID' };
        route_param 'id' => sub {
            summary 'Show user';
            get sub {
                my $params = shift;
                $USERS{ $params->{id} };
            };

            summary 'Delete user';
            del sub {
                my $params = shift;
                { success => delete $USERS{ $params->{id} } };
            };
        };

        summary 'NOP';
        get nop => sub { };
    };

    desc 'Echo API endpoint';
    resource echo => sub {
        params(optional => { name => 'data0', type => Any, default => "ёй" });
        get sub { shift };
    };

    run;

# DESCRIPTION

Raisin is a REST API micro framework for Perl.
It's designed to run on Plack, providing a simple DSL to easily develop RESTful APIs.
It was inspired by [Grape](https://github.com/intridea/grape).

# FUNCTIONS

## API DESCRIPTION

### resource

Adds a route to an application.

    resource user => sub { ... };

### route\_param

Define a route parameter as a namespace `route_param`.

    route_param id => sub { ... };

### del, get, patch, post, put

Shortcuts to add a `route` restricted to the corresponding HTTP method.

    get sub { 'GET' };

    del 'all' => sub { 'OK' };

    params(
        requires => { name => 'id', type => Int },
        optional => { name => 'key', type => Str },
    );
    get sub { 'GET' };

    desc 'Put data';
    params(
        required => { name => 'id', type => Int },
        optional => { name => 'name', type => Str },
    );
    put 'all' => sub {
        'PUT'
    };

### desc

Can be applied to `resource` or any of the HTTP method to add a verbose
explanation for an operation or for a resource.

    desc 'Some long explanation about an action';
    put sub { ... };

    desc 'Some exaplanation about a group of actions',
    resource => 'user' => sub { ... }

### summary

Can be applied to any of the HTTP method to add a short summary of
what the operation does.

    summary 'Some summary';
    put sub { ... };

### tags

A list of tags for API documentation control.
Tags can be used for logical grouping of operations by resources
or any other qualifier.

    tags 'delete', 'user';
    delete sub { ... };

By default tags are added automatically based on it's namespace but you always
can overwrite it using a `tags` function.

### params

Here you can define validations and coercion options for your parameters.
Can be applied to any HTTP method and/or `route_param` to describe parameters.

    params(
        requires => { name => 'name', type => Str },
        optional => { name => 'start', type => Int, default => 0 },
        optional => { name => 'count', type => Int, default => 10 },
    );
    get sub { ... };

    params(
        requires => { name => 'id', type => Int, desc => 'User ID' },
    );
    route_param 'id' => sub { ... };

For more see ["Validation-and-coercion" in Raisin](https://metacpan.org/pod/Raisin#Validation-and-coercion).

### api\_default\_format

Specifies default API format mode when formatter doesn't specified by API user.
E.g. URI is asked without an extension (`json`, `yaml`) or `Accept` header
isn't specified.

Default value: `YAML`.

    api_default_format 'json';

See also ["API-FORMATS" in Raisin](https://metacpan.org/pod/Raisin#API-FORMATS).

### api\_format

Restricts API to use only specified formatter to serialize and deserialize data.

Already exists [Raisin::Plugin::Format::JSON](https://metacpan.org/pod/Raisin::Plugin::Format::JSON) and [Raisin::Plugin::Format::YAML](https://metacpan.org/pod/Raisin::Plugin::Format::YAML).

    api_format 'json';

See also ["API-FORMATS" in Raisin](https://metacpan.org/pod/Raisin#API-FORMATS).

### api\_version

Sets up an API version header.

    api_version 1.23;

### plugin

Loads a Raisin module. A module options may be specified after the module name.
Compatible with [Kelp](https://metacpan.org/pod/Kelp) modules.

    plugin 'Swagger', enable => 'CORS';

### middleware

Adds a middleware to your application.

    middleware '+Plack::Middleware::Session' => { store => 'File' };
    middleware '+Plack::Middleware::ContentLength';
    middleware 'Runtime'; # will be loaded Plack::Middleware::Runtime

### mount

Mounts multiple API implementations inside another one.
These don't have to be different versions, but may be components of the same API.

In `RaisinApp.pm`:

    package RaisinApp;

    use Raisin::API;

    api_format 'json';

    mount 'RaisinApp::User';
    mount 'RaisinApp::Host';

    1;

### run

Returns the `PSGI` application.

## INSIDE ROUTE

### req

Provides quick access to the [Raisin::Request](https://metacpan.org/pod/Raisin::Request) object for the current route.

Use `req` to get access to request headers, params, etc.

    use DDP;
    p req->headers;
    p req->params;

    say req->header('X-Header');

See also [Plack::Request](https://metacpan.org/pod/Plack::Request).

### res

Provides quick access to the [Raisin::Response](https://metacpan.org/pod/Raisin::Response) object for the current route.

Use `res` to set up response parameters.

    res->status(403);
    res->headers(['X-Application' => 'Raisin Application']);

See also [Plack::Response](https://metacpan.org/pod/Plack::Response).

### param

Returns request parameters.
Without an argument will return an array of all input parameters.
Otherwise it will return the value of the requested parameter.

Returns [Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue) object.

    say param('key'); # -> value
    say param(); # -> { key => 'value', foo => 'bar' }

### include\_missing

Returns all declared parameters even if there is no value for a param.

See ["Declared-parameters" in Raisin](https://metacpan.org/pod/Raisin#Declared-parameters).

### session

Returns `psgix.session` hash. When it exists, you can retrieve and store
per-session data.

    # store param
    session->{hello} = 'World!';

    # read param
    say session->{name};

### present

Raisin hash a built-in `present` method, which accepts two arguments: an
object to be presented and an options associated with it. The options hash may
include `with` key, which is defined the entity to expose. See [Raisin::Entity](https://metacpan.org/pod/Raisin::Entity).

    my $artists = $schema->resultset('Artist');

    present data => $artists, with => 'MusicApp::Entity::Artist';
    present count => $artists->count;

[Raisin::Entity](https://metacpan.org/pod/Raisin::Entity) supports [DBIx::Class](https://metacpan.org/pod/DBIx::Class) and [Rose::DB::Object](https://metacpan.org/pod/Rose::DB::Object).

For details see examples in _examples/music-app_ and [Raisin::Entity](https://metacpan.org/pod/Raisin::Entity).

# PARAMETERS

Request parameters are available through the `params` `HASH`. This includes
GET, POST and PUT parameters, along with any named parameters you specify in
your route strings.

Parameters are automatically populated from the request body
on `POST` and `PUT` for form input, `JSON` and `YAML` content-types.

The request:

    curl localhost:5000/data -H Content-Type:application/json -d '{"id": "14"}'

The Raisin endpoint:

    post data => sub { param('id') };

Multipart `POST`s and `PUT`s are supported as well.

In the case of conflict between either of:

- route string parameters;
- GET, POST and PUT parameters;
- contents of request body on POST and PUT;

route string parameters will have precedence.

Query string and body parameters will be merged (see ["parameters" in Plack::Request](https://metacpan.org/pod/Plack::Request#parameters))

## Declared parameters

Raisin allows you to access only the parameters that have been declared by your
["params" in Raisin](https://metacpan.org/pod/Raisin#params) block.

By default you can get all declared parameter as a first argument passed to your
route subroutine.

Application:

    api_format 'json';

    post data => sub {
        my $params = shift;
        { data => $params };
    };

Request:

    curl -X POST -H "Content-Type: application/json" localhost:5000/signup -d '{"id": 42}'

Response:

    { "data": nil }

Once we add parameters requirements, Raisin will start returning only
the declared params.

Application:

    api_format 'json';

    params
        required => { name => 'id', type => Int };
        optional => { name => 'email', type => Str };
    post data => sub {
        my $params = shift;
        { data => $params };
    };

Request:

    curl -X POST -H "Content-Type: application/json" localhost:5000/signup -d '{"id": 42, "key": "value"}'

Response:

    { "data": { "id": 42 } }

By default declared parameters doesn't contain parameters that has `undef` value.
If you want to return all parameters you can use the `include_missing` function.

Application:

    api_format 'json';

    params
        required => { name => 'id', type => Int },
        optional => { name => 'email', type => Str };
    post data => sub {
        my $params = shift;
        { data => include_missing($params) };
    };

Request:

    curl -X POST -H "Content-Type: application/json" localhost:5000/signup -d '{"id": 42, "key": "value"}'

Response:

    { "data": { "id": 42, "email": null } }

## Validation and coercion

You can define validations and coercion options for your parameters using a
["params" in Raisin](https://metacpan.org/pod/Raisin#params) block.

Parameters can `requires` a value and can be an `optional`.
`optional` parameters can have a default value.

    params(
        requires => { name => 'name', type => Str },
        optional => { name => 'count', type => Int, default => 10 },
    );
    get sub {
        my $params = shift;
        "$params->{count}: $params->{name}";
    };

Note that default values will NOT be passed through to any validation options
specified.

Available arguments:

- name
- type
- default
- desc
- regex

## Types

Raisin supports Moo(se)-compatible type constraint so you can use any of the
[Moose](https://metacpan.org/pod/Moose), [Moo](https://metacpan.org/pod/Moo) or [Type::Tiny](https://metacpan.org/pod/Type::Tiny) type constraints.

By default [Raisin](https://metacpan.org/pod/Raisin) depends on [Type::Tiny](https://metacpan.org/pod/Type::Tiny) and it's [Types::Standard](https://metacpan.org/pod/Types::Standard) type
contraint library.

You can create your own types as well.
See [Type::Tiny::Manual](https://metacpan.org/pod/Type::Tiny::Manual) and [Moose::Manual::Types](https://metacpan.org/pod/Moose::Manual::Types).

# HOOKS

This blocks can be executed before or/and after every API call, using
`before`, `after`, `before_validation` and `after_validation`.

Before and after callbacks execute in the following order:

- before
- before\_validation
- after\_validation
- after

The block applies to every API call

    before sub {
        my $self = shift;
        say $self->req->method . "\t" . $self->req->path;
    };

    after_validation sub {
        my $self = shift;
        say $self->res->body;
    };

Steps 3 and 4 only happen if validation succeeds.

# API FORMATS

By default, Raisin supports `YAML`, `JSON`, and `TEXT` content types.
Default format is `YAML`.

Response format can be determined by `Accept header` or `route extension`.

Serialization takes place automatically. So, you do not have to call
`encode_json` in each `JSON` API implementation.

Your API can declare to support only one serializator by using ["api\_format" in Raisin](https://metacpan.org/pod/Raisin#api_format).

Custom formatters for existing and additional types can be defined with a
[Raisin::Plugin::Format](https://metacpan.org/pod/Raisin::Plugin::Format).

- JSON

    Call `JSON::encode_json` and `JSON::decode_json`.

- YAML

    Call `YAML::Dump` and `YAML::Load`.

- TEXT

    Call `Data::Dumper->Dump` if output data is not a string.

The order for choosing the format is the following.

- Use the route extension.
- Use the value of the `Accept` header.
- Fallback to default.

# LOGGING

Raisin has a built-in logger and supports for `Log::Dispatch`.
You can enable it by:

    plugin 'Logger', outputs => [['Screen', min_level => 'debug']];

Or use [Raisin::Logger](https://metacpan.org/pod/Raisin::Logger) with a `fallback` option:

    plugin 'Logger', fallback => 1;

Exports `log` subroutine.

    log(debug => 'Debug!');
    log(warn => 'Warn!');
    log(error => 'Error!');

See [Raisin::Plugin::Logger](https://metacpan.org/pod/Raisin::Plugin::Logger).

# API DOCUMENTATION

## Raisin script

You can see application routes with the following command:

    $ raisin examples/pod-synopsis-app/darth.pl
    GET     /user
    GET     /user/all
    POST    /user
    GET     /user/:id
    DELETE  /user/:id
    PUT     /user/:id
    GET     /echo

Including parameters:

    $ raisin --params examples/pod-synopsis-app/darth.pl
    GET     /user
       start Int{0}
       count Int{10}
    GET     /user/all
    POST    /user
      *name     Str
      *password Str
    email    Str
    GET     /user/:id
      *id Int
    DELETE  /user/:id
      *id Int
    PUT     /user/:id
      *id Int
    GET     /echo
      *data Any{ёй}

## Swagger

[Swagger](https://github.com/wordnik/swagger-core) compatible API documentations.

    plugin 'Swagger';

Documentation will be available on `http://<url>/api-docs` URL.
So you can use this URL in Swagger UI.

See [Raisin::Plugin::Swagger](https://metacpan.org/pod/Raisin::Plugin::Swagger).

# MIDDLEWARE

You can easily add any [Plack](https://metacpan.org/pod/Plack) middleware to your application using
`middleware` keyword. See ["middleware" in Raisin](https://metacpan.org/pod/Raisin#middleware).

# PLUGINS

Raisin can be extended using custom _modules_. Each new module must be a subclass
of the `Raisin::Plugin` namespace. Modules' job is to initialize and register new
methods into the web application class.

For more see ["plugin" in Raisin](https://metacpan.org/pod/Raisin#plugin) and [Raisin::Plugin](https://metacpan.org/pod/Raisin::Plugin).

# TESTING

See [Plack::Test](https://metacpan.org/pod/Plack::Test), [Test::More](https://metacpan.org/pod/Test::More) and etc.

    my $app = Plack::Util::load_psgi("$Bin/../script/raisinapp.pl");

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/user');

        subtest 'GET /user' => sub {
            if (!is $res->code, 200) {
                diag $res->content;
                BAIL_OUT 'FAILED!';
            }
            my $got = Load($res->content);
            isdeeply $got, $expected, 'Data!';
        };
    };

# DEPLOYING

Deploying a Raisin application is done the same way any other Plack
application is deployed:

    $ plackup -E deployment -s Starman app.psgi

## Kelp

    use Plack::Builder;
    use RaisinApp;
    use KelpApp;

    builder {
        mount '/' => KelpApp->new->run;
        mount '/api/rest' => RaisinApp->new;
    };

## Dancer

    use Plack::Builder;
    use Dancer ':syntax';
    use Dancer::Handler;
    use RaisinApp;

    my $dancer = sub {
        setting appdir => '/home/dotcloud/current';
        load_app 'My::App';
        Dancer::App->set_running_app('My::App');
        my $env = shift;
        Dancer::Handler->init_request_headers($env);
        my $req = Dancer::Request->new(env => $env);
        Dancer->dance($req);
    };

    builder {
        mount '/' => $dancer;
        mount '/api/rest' => RaisinApp->new;
    };

## Mojolicious::Lite

    use Plack::Builder;
    use RaisinApp;

    builder {
        mount '/' => builder {
            enable 'Deflater';
            require 'my_mojolicious-lite_app.pl';
        };

        mount '/api/rest' => RaisinApp->new;
    };

Also see [Plack::Builder](https://metacpan.org/pod/Plack::Builder), [Plack::App::URLMap](https://metacpan.org/pod/Plack::App::URLMap).

# EXAMPLES

Raisin comes with three instance in _example_ directory:

- pod-synopsis-app

    Basic example.

- music-app

    Shows the possibility of using ["present" in Raisin](https://metacpan.org/pod/Raisin#present) with [DBIx::Class](https://metacpan.org/pod/DBIx::Class)
    and [Rose::DB::Object](https://metacpan.org/pod/Rose::DB::Object).

- sample-app

    Shows an example of complex application.

# ROADMAP

- `param` doesn't work as expected;
- Support for hypermedia ([HAL](http://stateless.co/hal_specification.html), [Link headers](http://www.w3.org/wiki/LinkHeader));
- Versioning support;
- Nested params declaration;
- Mount API's in any place of `resource` block;

# GITHUB

[https://github.com/khrt/Raisin](https://github.com/khrt/Raisin)

# ACKNOWLEDGEMENTS

This module was inspired both by Grape and [Kelp](https://metacpan.org/pod/Kelp),
which was inspired by [Dancer](https://metacpan.org/pod/Dancer), which in its turn was inspired by Sinatra.

# AUTHOR

Artur Khabibullin - rtkh <at> cpan.org

# LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.
