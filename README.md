# NAME

Raisin - A REST-like API micro-framework for Perl.

# SYNOPSYS

    use Raisin::DSL;

    my %USERS = (
        1 => {
            name => 'Darth Wader',
            password => 'death',
            email => 'darth@deathstar.com',
        },
        2 => {
            name => 'Luke Skywalker',
            password => 'qwerty',
            email => 'l.skywalker@jedi.com',
        },
    );

    namespace '/user' => sub {
        get params => [
            #required/optional => [name, type, default, regex]
            optional => ['start', $Raisin::Types::Integer, 0],
            optional => ['count', $Raisin::Types::Integer, 10],
        ],
        sub {
            my $params = shift;
            my ($start, $count) = ($params->{start}, $params->{count});

            my @users
                = map { { id => $_, %{ $USERS{$_} } } }
                  sort { $a <=> $b } keys %USERS;

            $start = $start > scalar @users ? scalar @users : $start;
            $count = $count > scalar @users ? scalar @users : $count;

            my @slice = @users[$start .. $count];
            { data => \@slice }
        };

        post params => [
            required => ['name', $Raisin::Types::String],
            required => ['password', $Raisin::Types::String],
            optional => ['email', $Raisin::Types::String, undef, qr/.+\@.+/],
        ],
        sub {
            my $params = shift;

            my $id = max(keys %USERS) + 1;
            $USERS{$id} = $params;

            { success => 1 }
        };

        route_param 'id' => $Raisin::Types::Integer,
        sub {
            get sub {
                my $params = shift;
                %USERS{ $params->{id} };
            };
        };
    };

    run;

# DESCRIPTION

Raisin is a REST-like API micro-framework for Perl.
It's designed to run on Plack, providing a simple DSL to easily develop RESTful APIs.
It was inspired by [Grape](https://github.com/intridea/grape).

# KEYWORDS

### namespace

    namespace user => sub { ... };

### route\_param

    route_param id => $Raisin::Types::Integer, sub { ... };

### delete, get, post, put

These are shortcuts to `route` restricted to the corresponding HTTP method.

    get sub { 'GET' };

    get params => [
        required => ['id', $Raisin::Types::Integer],
        optional => ['key', $Raisin::Types::String],
    ],
    sub { 'GET' };

### req

An alias for `$self->req`, this provides quick access to the
[Raisin::Request](https://metacpan.org/pod/Raisin::Request) object for the current route.

### res

An alias for `$self->res`, this provides quick access to the
[Raisin::Response](https://metacpan.org/pod/Raisin::Response) object for the current route.

### params

An alias for `$self->params` that gets the GET and POST parameters.
When used with no arguments, it will return an array with the names of all http
parameters. Otherwise, it will return the value of the requested http parameter.

Returns [Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue) object.

### session

An alias for `$self->session` that returns (optional) psgix.session hash.
When it exists, you can retrieve and store per-session data from and to this hash.

### api\_format

Load a `Raisin::Plugin::Format` plugin.

Already exists [Raisin::Plugin::Format::JSON](https://metacpan.org/pod/Raisin::Plugin::Format::JSON) and [Raisin::Plugin::Format::YAML](https://metacpan.org/pod/Raisin::Plugin::Format::YAML).

    api_format 'JSON';

### plugin

Loads a Raisin module. The module options may be specified after the module name.
Compatible with [Kelp](https://metacpan.org/pod/Kelp) modules.

    plugin 'Logger' => outputs => [['Screen', min_level => 'debug']];

### middleware

Loads middleware to your application.

    middleware '+Plack::Middleware::Session' => { store => 'File' };
    middleware '+Plack::Middleware::ContentLength';

### mount

Mount multiple API implementations inside another one.  These don't have to be
different versions, but may be components of the same API.

In `RaisinApp.pm`:

    package RaisinApp;

    use Raisin::DSL;

    api_format 'JSON';

    mount 'RaisinApp::User';
    mount 'RaisinApp::Host';

    1;

### run, new

Creates and returns a PSGI ready subroutine, and makes the app ready for `Plack`.

## Parameters

Request parameters are available through the params hash object. This includes
GET, POST and PUT parameters, along with any named parameters you specify in
your route strings.

Parameters are automatically populated from the request body on POST and PUT
for form input, JSON and YAML content-types.

In the case of conflict between either of:

- route string parameters
- GET, POST and PUT parameters
- the contents of the request body on POST and PUT

route string parameters will have precedence.

Query string and body parameters will be merged (see ["parameters" in Plack::Request](https://metacpan.org/pod/Plack::Request#parameters))

### Validation and coercion

You can define validations and coercion options for your parameters using a params block.

Parameters can be `required` and `optional`. `optional` parameters can have a
default value.

    get params => [
        required => ['name', $Raisin::Types::String],
        optional => ['number', $Raisin::Types::Integer, 10],
    ],
    sub {
        my $params = shift;
        "$params->{number}: $params->{name}";
    };



Positional arguments:

- name
- type
- default value
- regex

Optional parameters can have a default value.

### Types

TODO
See [Raisin::Types](https://metacpan.org/pod/Raisin::Types)

## Hooks

This blocks can be executed before or after every API call, using
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

By default, Raisin supports `YAML`, `JSON`, and `TXT` content-types.
The default format is `TXT`.

Serialization takes place automatically. For example, you do not have to call
`encode_json` in each `JSON` API implementation.

Your API can declare which types to support by using `api_format`.

    api_format 'JSON';

Custom formatters for existing and additional types can be defined with a
[Raisin::Plugin::Format](https://metacpan.org/pod/Raisin::Plugin::Format).

Built-in formats are the following:

- `JSON`: call JSON::encode\_json.
- `YAML`: call YAML::Dump.
- `TXT`: call Data::Dumper->Dump if not SCALAR.

The order for choosing the format is the following.

- Use the `api_format` set by the `api_format` option, if specified.
- Default to `TXT`.

# HEADERS

TODO
set headers
get headers

# AUTHENTICATION

TODO
Built-in plugin [Raisin::Plugin::Authentication](https://metacpan.org/pod/Raisin::Plugin::Authentication)
[Raisin::Plugin::Authentication::Basic](https://metacpan.org/pod/Raisin::Plugin::Authentication::Basic)
[Raisin::Plugin::Authentication::Digest](https://metacpan.org/pod/Raisin::Plugin::Authentication::Digest)

# LOGGING

TODO
Built-in plugin [Raisin::Plugin::Logger](https://metacpan.org/pod/Raisin::Plugin::Logger).

# MIDDLEWARE

You can easily add any [Plack](https://metacpan.org/pod/Plack) middleware to your application using
`middleware` keyword.

# PLUGINS

Raisin can be extended using custom _modules_. Each new module must be a subclass
of the `Raisin::Plugin` namespace. Modules' job is to initialize and register new
methods into the web application class.

For more see [Raisin::Plugin](https://metacpan.org/pod/Raisin::Plugin).

# TESTING

TODO
[Plack::Test](https://metacpan.org/pod/Plack::Test)

# DEPLOYING

See examples and/or [Plack::App::URLMap](https://metacpan.org/pod/Plack::App::URLMap).
In `app.psgi`:

    use Plack::Builder;

    use RaisinApp;
    use KelpApp;

    builder {
        mount '/' => KelpApp->new->run;
        mount '/api/rest' => RaisinApp->new;
    };

# GitHub

https://github.com/khrt/Raisin

# AUTHOR

Artur Khabibullin - khrt <at> ya.ru

# ACKNOWLEDGEMENTS

This module was inspired by [Kelp](https://metacpan.org/pod/Kelp), which was inspired by [Dancer](https://metacpan.org/pod/Dancer),
which in its turn was inspired by Sinatra.

# LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.
