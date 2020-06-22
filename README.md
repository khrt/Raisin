# NAME

Raisin - A REST API microframework for Perl.

# VERSION

version 0.90

# SYNOPSIS

    use HTTP::Status qw(:constants);
    use List::Util qw(max);
    use Raisin::API;
    use Types::Standard qw(HashRef Any Int Str);

    my %USERS = (
        1 => {
            first_name => 'Darth',
            last_name => 'Wader',
            password => 'deathstar',
            email => 'darth@deathstar.com',
        },
        2 => {
            first_name => 'Luke',
            last_name => 'Skywalker',
            password => 'qwerty',
            email => 'l.skywalker@jedi.com',
        },
    );

    plugin 'Logger', fallback => 1;
    app->log( debug => 'Starting Raisin...' );

    middleware 'CrossOrigin',
        origins => '*',
        methods => [qw/DELETE GET HEAD OPTIONS PATCH POST PUT/],
        headers => [qw/accept authorization content-type api_key_token/];

    plugin 'Swagger';

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
            optional('start', type => Int, default => 0, desc => 'Pager (start)'),
            optional('count', type => Int, default => 10, desc => 'Pager (count)'),
        );
        get sub {
            my $params = shift;

            my @users
                = map { { id => $_, %{ $USERS{$_} } } }
                  sort { $a <=> $b } keys %USERS;

            my $max_count = scalar(@users) - 1;
            my $start = $params->{start} > $max_count ? $max_count : $params->{start};
            my $end = $params->{count} > $max_count ? $max_count : $params->{count};

            my @slice = @users[$start .. $end];
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
            requires('user', type => HashRef, desc => 'User object', group {
                requires('first_name', type => Str, desc => 'First name'),
                requires('last_name', type => Str, desc => 'Last name'),
                requires('password', type => Str, desc => 'User password'),
                optional('email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email'),
            }),
        );
        post sub {
            my $params = shift;

            my $id = max(keys %USERS) + 1;
            $USERS{$id} = $params->{user};

            res->status(HTTP_CREATED);
            { success => 1 }
        };

        desc 'Actions on the user';
        params requires('id', type => Int, desc => 'User ID');
        route_param 'id' => sub {
            summary 'Show user';
            get sub {
                my $params = shift;
                $USERS{ $params->{id} };
            };

            summary 'Delete user';
            del sub {
                my $params = shift;
                delete $USERS{ $params->{id} };
                res->status(HTTP_NO_CONTENT);
                undef;
            };
        };
    };

    run;

# DESCRIPTION

Raisin is a REST API microframework for Perl.
It's designed to run on Plack, providing a simple DSL to develop RESTful APIs easily.
It was inspired by [Grape](https://github.com/intridea/grape).

# FUNCTIONS

## API DESCRIPTION

### resource

Adds a route to an application.

    resource user => sub { ... };

### route\_param

Defines a route parameter as a resource `id` which can be anything if type
isn't specified for it.

    route_param id => sub { ... };

Raisin allows you to nest `route_param`:

    params requires => { name => 'id', type => Int };
    route_param id => sub {
        get sub { ... };

        params requires => { name => 'sub_id', type => Int };
        route_param sub_id => sub {
            ...
        };
    };

### del, get, patch, post, put

Shortcuts to add a `route` restricted to the corresponding HTTP method.

    get sub { 'GET' };

    del 'all' => sub { 'OK' };

    params(
        requires('id', type => Int),
        optional('key', type => Str),
    );
    get sub { 'GET' };

    desc 'Put data';
    params(
        required('id', type => Int),
        optional('name', type => Str),
    );
    put 'all' => sub {
        'PUT'
    };

### desc

Adds a description to `resource` or any of the HTTP methods.
Useful for OpenAPI as it's shown there as a description of an action.

    desc 'Some long explanation about an action';
    put sub { ... };

    desc 'Some exaplanation about a group of actions',
    resource => 'user' => sub { ... }

### summary

Same as ["desc"](#desc) but shorter.

    summary 'Some summary';
    put sub { ... };

### tags

Tags can be used for logical grouping of operations by resources
or any other qualifier. Using in API description.

    tags 'delete', 'user';
    delete sub { ... };

By default tags are added automatically based on it's namespace but you always
can overwrite it using the function.

### entity

Describes response object which will be used to generate OpenAPI description.

    entity 'MusicApp::Entity::Album';
    get {
        my $albums = $schema->resultset('Album');
        present data => $albums, with => 'MusicApp::Entity::Album';
    };

### params

Defines validations and coercion options for your parameters.
Can be applied to any HTTP method and/or ["route\_param"](#route_param) to describe parameters.

    params(
        requires('name', type => Str),
        optional('start', type => Int, default => 0),
        optional('count', type => Int, default => 10),
    );
    get sub { ... };

    params(
        requires('id', type => Int, desc => 'User ID'),
    );
    route_param 'id' => sub { ... };

For more see ["Validation-and-coercion" in Raisin](https://metacpan.org/pod/Raisin#Validation-and-coercion).

### api\_default\_format

Specifies default API format mode when formatter isn't specified by API user.
E.g. if URI is asked without an extension (`json`, `yaml`) or `Accept` header
isn't specified the default format will be used.

Default value: `YAML`.

    api_default_format 'json';

See also ["API-FORMATS" in Raisin](https://metacpan.org/pod/Raisin#API-FORMATS).

### api\_format

Restricts API to use only specified formatter to serialize and deserialize data.

Already exists [Raisin::Encoder::JSON](https://metacpan.org/pod/Raisin::Encoder::JSON), [Raisin::Encoder::YAML](https://metacpan.org/pod/Raisin::Encoder::YAML),
and [Raisin::Encoder::Text](https://metacpan.org/pod/Raisin::Encoder::Text), but you can always register your own
using ["register\_encoder"](#register_encoder).

    api_format 'json';

See also ["API-FORMATS" in Raisin](https://metacpan.org/pod/Raisin#API-FORMATS).

### api\_version

Sets up an API version header.

    api_version 1.23;

### plugin

Loads a Raisin module. A module options may be specified after the module name.
Compatible with [Kelp](https://metacpan.org/pod/Kelp) modules.

    plugin 'Swagger';

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

### register\_decoder

Registers a third-party parser (decoder).

    register_decoder(xml => 'My::Parser::XML');

See also [Raisin::Decoder](https://metacpan.org/pod/Raisin::Decoder).

### register\_encoder

Registers a third-party formatter (encoder).

    register_encoder(xml => 'My::Formatter::XML');

See also [Raisin::Encoder](https://metacpan.org/pod/Raisin::Encoder).

### run

Returns the `PSGI` application.

## CONTROLLER

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

# ALLOWED METHODS

When you add a route for a resource, a route for the OPTIONS method will also be
added. The response to an OPTIONS request will include an "Allow" header listing
the supported methods.

    get 'count' => sub {
        { count => $count };
    };

    params(
        requires('num', type => Int, desc => 'Value to add to the count.'),
    );
    put 'count' => sub {
        my $params = shift;
        $count += $params->{num};
        { count: $count };
    };


    curl -v -X OPTIONS http://localhost:5000/count

    > OPTIONS /count HTTP/1.1
    > Host: localhost:5000
    >
    * HTTP 1.0, assume close after body
    < HTTP/1.1 204 No Content
    < Allow: GET, OPTIONS, PUT

If a request for a resource is made with an unsupported HTTP method, an HTTP 405
(Method Not Allowed) response will be returned.

    curl -X DELETE -v http://localhost:3000/count

    > DELETE /count HTTP/1.1
    > Host: localhost:5000
    >
    * HTTP 1.0, assume close after body
    < HTTP/1.1 405 Method Not Allowed
    < Allow: OPTIONS, GET, PUT

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

- path parameters;
- GET, POST and PUT parameters;
- contents of request body on POST and PUT;

Path parameters have precedence.

Query string and body parameters will be merged (see ["parameters" in Plack::Request](https://metacpan.org/pod/Plack::Request#parameters))

## Declared parameters

Raisin allows you to access only the parameters that have been declared by you in
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

Once we add parameters block, Raisin will start return only the declared parameters.

Application:

    api_format 'json';

    params(
        requires('id', type => Int),
        optional('email', type => Str)
    );
    post data => sub {
        my $params = shift;
        { data => $params };
    };

Request:

    curl -X POST -H "Content-Type: application/json" localhost:5000/signup -d '{"id": 42, "key": "value"}'

Response:

    { "data": { "id": 42 } }

By default declared parameters don't contain parameters which have no value.
If you want to return all parameters you can use the `include_missing` function.

Application:

    api_format 'json';

    params(
        requires('id', type => Int),
        optional('email', type => Str)
    );
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

Parameters can `requires` value or can be `optional`.
`optional` parameters can have default value.

    params(
        requires('name', type => Str),
        optional('count', type => Int, default => 10),
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
- in

## Nested Parameters

### Hash

Use a keyword `group` to define a group of parameters which is enclosed to
the parent `HashRef` parameter.

    params(
        requires('name', type => HashRef, group {
            requires('first_name', type => Str),
            requires('last_name', type => Str),
        })
    )

### Array

Use `ArrayRef[*]` types from your compatible type library to define arrays.

    requires('list', type => ArrayRef[Int], desc => 'List of integers')

## Types

Raisin supports Moo(se)-compatible type constraint so you can use any of the
[Moose](https://metacpan.org/pod/Moose), [Moo](https://metacpan.org/pod/Moo) or [Type::Tiny](https://metacpan.org/pod/Type::Tiny) type constraints.

By default [Raisin](https://metacpan.org/pod/Raisin) depends on [Type::Tiny](https://metacpan.org/pod/Type::Tiny) and it's [Types::Standard](https://metacpan.org/pod/Types::Standard) type
contraint library.

You can create your own types as well.
See [Type::Tiny::Manual](https://metacpan.org/pod/Type::Tiny::Manual) and [Moose::Manual::Types](https://metacpan.org/pod/Moose::Manual::Types).

# HOOKS

Those blocks can be executed before or/and after every API call, using
`before`, `after`, `before_validation` and `after_validation`.

Callbacks execute in the following order:

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

Steps `after_validation` and `after` are executed only if validation succeeds.

Every callback has only one argument as an input parameter which is [Raisin](https://metacpan.org/pod/Raisin)
object. For more information of available methods see ["CONTROLLER" in Raisin](https://metacpan.org/pod/Raisin#CONTROLLER).

# API FORMATS

By default, Raisin supports `YAML`, `JSON`, and `TEXT` content types.
Default format is `YAML`.

Response format can be determined by `Accept header` or `route extension`.

Serialization takes place automatically. So, you do not have to call
`encode_json` in each `JSON` API implementation.

Your API can declare to support only one serializator by using ["api\_format" in Raisin](https://metacpan.org/pod/Raisin#api_format).

Custom formatters for existing and additional types can be defined with a
[Raisin::Encoder](https://metacpan.org/pod/Raisin::Encoder)/[Raisin::Decoder](https://metacpan.org/pod/Raisin::Decoder).

- JSON

    Call `JSON::encode_json` and `JSON::decode_json`.

- YAML

    Call `YAML::Dump` and `YAML::Load`.

- Text

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

The plugin registers a `log` subroutine to [Raisin](https://metacpan.org/pod/Raisin). Below are examples of
how to use it.

    app->log(debug => 'Debug!');
    app->log(warn => 'Warn!');
    app->log(error => 'Error!');

`app` is a [Raisin](https://metacpan.org/pod/Raisin) instance, so you can use `$self` instead of `app` where
it is possible.

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

## OpenAPI/Swagger

[Swagger](http://swagger.io) compatible API documentations.

    plugin 'Swagger';

Documentation will be available on `http://<url>/swagger.json` URL.
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

See also [Plack::Builder](https://metacpan.org/pod/Plack::Builder), [Plack::App::URLMap](https://metacpan.org/pod/Plack::App::URLMap).

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

- Versioning support;
- Mount API's in any place of `resource` block;

# GITHUB

[https://github.com/khrt/Raisin](https://github.com/khrt/Raisin)

# ACKNOWLEDGEMENTS

This module was inspired both by Grape and [Kelp](https://metacpan.org/pod/Kelp),
which was inspired by [Dancer](https://metacpan.org/pod/Dancer), which in its turn was inspired by Sinatra.

# AUTHOR

Artur Khabibullin <rtkh@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
