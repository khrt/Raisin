package Raisin;

use strict;
use warnings;

use Carp qw(croak carp longmess);
use Plack::Util;

use Raisin::Request;
use Raisin::Response;
use Raisin::Routes;

use Raisin::Util;

use constant DEFAULT_SERIALIZER => 'Raisin::Plugin::Format::TEXT';

our $VERSION = '0.29';

sub new {
    my ($class, %args) = @_;
    my $self = bless { %args }, $class;

    $self->{routes} = Raisin::Routes->new;
    $self->{mounted} = [];
    $self->{middleware} = {};

    $self;
}

sub mount_package {
    my ($self, $package) = @_;
    push @{ $self->{mounted} }, $package;
    Plack::Util::load_class($package);
}

sub load_plugin {
    my ($self, $name, @args) = @_;
    return if $self->{loaded_plugins}{$name};

    my $class = Plack::Util::load_class($name, 'Raisin::Plugin');
    my $module = $self->{loaded_plugins}{$name} = $class->new($self);

    $module->build(@args);
}

sub add_middleware {
    my ($self, $name, @args) = @_;
    $self->{middleware}{$name} = \@args;
}

# Routes
sub routes { shift->{routes} }
sub add_route { shift->routes->add(@_) }

# Hooks
sub hook {
    my ($self, $name) = @_;
    $self->{hooks}{$name} || sub {};
}

sub add_hook {
    my ($self, $name, $code) = @_;
    $self->{hooks}{$name} = $code;
}

# Application
sub run {
    my $self = shift;
    my $app = sub { $self->psgi(@_) };

    # Add middleware
    for my $class (keys %{ $self->{middleware} }) {
        # Make sure the middleware was not already loaded
        next if $self->{_loaded_middleware}->{$class}++;

        my $mw = Plack::Util::load_class($class, 'Plack::Middleware');
        my $args = $self->{middleware}{$class};
        $app = $mw->wrap($app, @$args);
    }

    return $app;
}

sub psgi {
    my ($self, $env) = @_;

    # Diffrent for each response
    my $req = $self->req(Raisin::Request->new($self, $env));
    my $res = $self->res(Raisin::Response->new($self));

    # Build API docs if needed
    if ($self->can('build_api_docs')) {
        $self->build_api_docs;
    }

    # HOOK Before
    $self->hook('before')->($self);

    # Find route
    my $routes = $self->routes->find($req->method, $req->path);

    if (!@$routes) {
        $res->render_404;
        return $res->finalize;
    }

    eval {
        foreach my $route (@$routes) {
            # Validate code variable
            my $code = $route->code;
            if (!$code || (ref($code) && ref($code) ne 'CODE')) {
                croak 'Invalid endpoint for ' . $req->path;
            }

            # Log
            if ($self->can('logger')) {
                $self->logger(info => $req->method . q{ } . $route->path);
            }

            # HOOK Before validation
            $self->hook('before_validation')->($self);

            # Populate and validate declared params
            if (not $req->prepare_params($route->params, $route->named)) {
                carp '* ' . 'INVALID PARAMS! ' x 5;
                $res->render_error(400, 'Invalid params!');
                last;
            }

            # HOOK After validation
            $self->hook('after_validation')->($self);

            # Eval code
            my $data = $code->($req->declared_params);

            if (defined $data) {
                # Handle delayed response
                return $data if ref($data) eq 'CODE'; # TODO: check delayed responses

                # Detect output format
                my $format = $route->format || $req->header('Accept');
                $res->render($format, $data) if not $res->rendered;
            }

            # HOOK After
            $self->hook('after')->($self);
        }

        if (!$res->rendered) {
            croak 'Nothing rendered!';
        }

        1;
    } or do {
        my $e = longmess($@);
        $res->render_500($e);
    };

    $self->finalize;
}

# Finalize response
sub before_finalize {
    my $self = shift;
    $self->res->header('X-Framework' => "Raisin $VERSION");

    if ($self->api_version) {
        $self->res->header('X-API-Version' => $self->api_version);
    }
}

sub finalize {
    my $self = shift;
    $self->before_finalize;
    $self->res->finalize;
}

# Application defaults
sub api_version {
    my ($self, $version) = @_;
    $self->{version} = $version if $version;
    $self->{version}
}

sub api_format {
    my ($self, $name) = @_;
    $name = $name =~ /\+/x ? $name : "Format::${\uc($name)}";
    $self->load_plugin($name);
}

# Request and Response and shortcuts
sub req {
    my ($self, $req) = @_;
    $self->{req} = $req if $req;
    $self->{req};
}

sub res {
    my ($self, $res) = @_;
    $self->{res} = $res if $res;
    $self->{res};
}

sub param { shift->req->parameters->mixed }

sub session {
    my $self = shift;

    if (not $self->req->env->{'psgix.session'}) {
        croak "No Session middleware wrapped";
    }

    $self->req->session;
}

1;

__END__

=head1 NAME

Raisin - REST-like API web micro-framework for Perl.

=head1 SYNOPSIS

    use Raisin::API;
    use Raisin::Types;

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

    namespace user => sub {
        params [
            #required/optional => [name, type, default, regex]
            optional => ['start', 'Raisin::Types::Integer', 0],
            optional => ['count', 'Raisin::Types::Integer', 10],
        ],
        get => sub {
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

        get 'all' => sub {
            my @users
                = map { { id => $_, %{ $USERS{$_} } } }
                  sort { $a <=> $b } keys %USERS;
            { data => \@users }
        };

        params [
            required => ['name', 'Raisin::Types::String'],
            required => ['password', 'Raisin::Types::String'],
            optional => ['email', 'Raisin::Types::String', undef, qr/.+\@.+/],
        ],
        post => sub {
            my $params = shift;

            my $id = max(keys %USERS) + 1;
            $USERS{$id} = $params;

            { success => 1 }
        };

        route_param 'id' => 'Raisin::Types::Integer',
        sub {
            get sub {
                my $params = shift;
                $USERS{ $params->{id} };
            };
        };
    };

    run;

=head1 DESCRIPTION

Raisin is a REST-like API web micro-framework for Perl.
It's designed to run on Plack, providing a simple DSL to easily develop RESTful APIs.
It was inspired by L<Grape|https://github.com/intridea/grape>.

=head1 KEYWORDS

=head2 namespace

Adds a route to application.

    namespace user => sub { ... };

=head2 route_param

Define a route parameter as a namespace C<route_param>.

    route_param id => 'Raisin::Types::Integer', sub { ... };

=head2 params, delete, get, patch, post, put

It is are shortcuts to C<route> restricted to the corresponding HTTP method.

Each method could consists of max three parameters:

=over

=item * params - optional only if didn't starts from params keyword, required otherwise;

=item * path - optional;

=item * subroutine - required;

=back

Where only C<subroutine> is required.

    get sub { 'GET' };

    delete 'all' => sub { 'OK' };

    params [
        required => ['id', 'Raisin::Types::Integer'],
        optional => ['key', 'Raisin::Types::String'],
    ],
    get => sub { 'GET' };

    params [
        required => ['id', 'Raisin::Types::Integer'],
        optional => ['name', 'Raisin::Types::String'],
    ],
    put => 'all' => sub {
        'PUT'
    };

=head2 req

An alias for C<$self-E<gt>req>, this provides quick access to the
L<Raisin::Request> object for the current route.

Use C<req> to get access to the request headers, params, etc.

    use DDP;
    p req->headers;
    p req->params;

    say req->header('X-Header');

See also L<Plack::Request>.

=head2 res

An alias for C<$self-E<gt>res>, this provides quick access to the
L<Raisin::Response> object for the current route.

Use C<res> to set up response parameters.

    res->status(403);
    res->headers(['X-Application' => 'Raisin Application']);

See also L<Plack::Response>.

=head2 param

An alias for C<$self-E<gt>params> that gets the GET and POST parameters.
When used with no arguments, it will return an array with the names of all http
parameters. Otherwise, it will return the value of the requested http parameter.

Returns L<Hash::MultiValue> object.

    say param('key'); # -> value
    say param(); # -> { key => 'value' }

=head2 session

An alias for C<$self-E<gt>session> that returns (optional) psgix.session hash.
When it exists, you can retrieve and store per-session data from and to this hash.

    # store param
    session->{hello} = 'World!';

    # read param
    say session->{name};

=head2 api_version

Set an API version header.

    api_version 1.23;

=head2 api_format

Loads a plugin from C<Raisin::Plugin::Format> namespace.

Already exists L<Raisin::Plugin::Format::JSON> and L<Raisin::Plugin::Format::YAML>.

    api_format 'json';

=head2 plugin

Loads a Raisin module. The module options may be specified after the module name.
Compatible with L<Kelp> modules.

    plugin 'Logger' => outputs => [['Screen', min_level => 'debug']];

=head2 middleware

Loads middleware to your application.

    middleware '+Plack::Middleware::Session' => { store => 'File' };
    middleware '+Plack::Middleware::ContentLength';
    middleware 'Runtime'; # will be loaded Plack::Middleware::Runtime

=head2 mount

Mount multiple API implementations inside another one.  These don't have to be
different versions, but may be components of the same API.

In C<RaisinApp.pm>:

    package RaisinApp;

    use Raisin::API;

    api_format 'json';

    mount 'RaisinApp::User';
    mount 'RaisinApp::Host';

    1;

=head2 run, new

Creates and returns a PSGI ready subroutine, and makes the app ready for C<Plack>.

=head1 PARAMETERS

Request parameters are available through the params hash object. This includes
GET, POST and PUT parameters, along with any named parameters you specify in
your route strings.

Parameters are automatically populated from the request body on POST and PUT
for form input, C<JSON> and C<YAML> content-types.

In the case of conflict between either of:

=over

=item *

route string parameters

=item *

GET, POST and PUT parameters

=item *

the contents of the request body on POST and PUT

=back

route string parameters will have precedence.

Query string and body parameters will be merged (see L<Plack::Request/parameters>)

=head2 Validation and coercion

You can define validations and coercion options for your parameters using a params block.

Parameters can be C<required> and C<optional>. C<optional> parameters can have a
default value.

    get params => [
        required => ['name', 'Raisin::Types::String'],
        optional => ['number', 'Raisin::Types::Integer', 10],
    ],
    sub {
        my $params = shift;
        "$params->{number}: $params->{name}";
    };


Positional arguments:

=over

=item *

name

=item *

type

=item *

default value

=item *

regex

=back

Optional parameters can have a default value.

=head2 Types

Here is built-in types

=over

=item *

L<Raisin::Types::Float>

=item *

L<Raisin::Types::Integer>

=item *

L<Raisin::Types::String>

=item *

L<Raisin::Types::Scalar>

=back

You can create your own types as well. See examples in L<Raisin::Types>.
Also see L<Raisin::Types::Base>.

=head1 HOOKS

This blocks can be executed before or after every API call, using
C<before>, C<after>, C<before_validation> and C<after_validation>.

Before and after callbacks execute in the following order:

=over

=item *

before

=item *

before_validation

=item *

after_validation

=item *

after

=back

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

=head1 API FORMATS

By default, Raisin supports C<YAML>, C<JSON>, and C<TEXT> content-types.
The default format is C<TEXT>.

Response format can be determined by Accept header or route extension.

Serialization takes place automatically. For example, you do not have to call
C<encode_json> in each C<JSON> API implementation.

Your API can declare which types to support by using C<api_format>.

    api_format 'json';

Custom formatters for existing and additional types can be defined with a
L<Raisin::Plugin::Format>.

=over

=item JSON

Call C<JSON::encode_json> and C<JSON::decode_json>.

=item YAML

Call C<YAML::Dump> and C<JSON::Load>.

=item TEXT

Call C<Data::Dumper-E<gt>Dump> if output data is not a string.

=back

The order for choosing the format is the following.

=over

=item *

Use the route extension.

=item *

Use the value of the C<Accept> header.

=item *

Use the C<api_format> if specified.

=item *

Fallback to C<TEXT>.

=back

=head1 AUTHENTICATION

TODO
L<Raisin::Plugin::Auth>
L<Raisin::Plugin::Auth::Basic>
L<Raisin::Plugin::Auth::Token>

=head1 LOGGING

Raisin has a built-in logger based on C<Log::Dispatch>. You can enable it by

    plugin 'Logger' => outputs => [['Screen', min_level => 'debug']];

Exports C<logger> subroutine.

    logger(debug => 'Debug!');
    logger(warn => 'Warn!');
    logger(error => 'Error!');

See L<Raisin::Plugin::Logger>.

=head1 API DOCUMENTATION

=head2 Raisin script

You can see application routes with the following command:

    $ raisin --routes examples/singular/routes.pl
      GET     /user
      GET     /user/all
      POST    /user
      GET     /user/{id}
      PUT     /user/{id}
      GET     /user/{id}/bump
      PUT     /user/{id}/bump
      GET     /failed

Verbose output with route parameters:

    $ raisin --routes --params examples/singular/routes.pl
      GET     /user
        optional: `start', type: Integer, default: 0
        optional: `count', type: Integer, default: 10

      GET     /user/all

      POST    /user
        required: `name', type: String
        required: `password', type: String
        optional: `email', type: String

      GET     /user/{id}
        required: `id', type: Integer

      PUT     /user/{id}
        optional: `password', type: String
        optional: `email', type: String
        required: `id', type: Integer

      GET     /user/{id}/bump
        required: `id', type: Integer

      PUT     /user/{id}/bump
        required: `id', type: Integer

      GET     /failed

      GET     /params

=head2 Swagger

L<Swagger|https://github.com/wordnik/swagger-core> compatible API documentations.

    plugin 'APIDocs';

Documentation will be available on C<http://E<lt>urlE<gt>/api-docs> URL.
So you can use this URL in Swagger UI.

For more see L<Raisin::Plugin::APIDocs>.

=head1 MIDDLEWARE

You can easily add any L<Plack> middleware to your application using
C<middleware> keyword. See L<Raisin/middleware>.

=head1 PLUGINS

Raisin can be extended using custom I<modules>. Each new module must be a subclass
of the C<Raisin::Plugin> namespace. Modules' job is to initialize and register new
methods into the web application class.

For more see L<Raisin/plugin> and L<Raisin::Plugin>.

=head1 TESTING

See L<Plack::Test>, L<Test::More> and etc.

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

=head1 DEPLOYING

Deploying a Raisin application is done the same way any other Plack
application is deployed:

    > plackup -E deployment -s Starman app.psgi

=head2 Kelp

    use Plack::Builder;
    use RaisinApp;
    use KelpApp;

    builder {
        mount '/' => KelpApp->new->run;
        mount '/api/rest' => RaisinApp->new;
    };

=head2 Dancer

    use Plack::Builder;
    use Dancer ':syntax';
    use Dancer::Handler;
    use RaisinApp;

    my $dancer = sub {
        setting appdir => '/home/dotcloud/current';
        load_app "My::App";
        Dancer::App->set_running_app("My::App");
        my $env = shift;
        Dancer::Handler->init_request_headers($env);
        my $req = Dancer::Request->new(env => $env);
        Dancer->dance($req);
    };

    builder {
        mount "/" => $dancer;
        mount '/api/rest' => RaisinApp->new;
    };

=head2 Mojolicious::Lite

    use Plack::Builder;
    use RaisinApp;

    builder {
        mount '/' => builder {
            enable 'Deflater';
            require 'my_mojolicious-lite_app.pl';
        };

        mount '/api/rest' => RaisinApp->new;
    };

Also see L<Plack::Builder>, L<Plack::App::URLMap>.

=head1 EXAMPLES

See examples.

=head1 GITHUB

L<https://github.com/khrt/Raisin|https://github.com/khrt/Raisin>

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 ACKNOWLEDGEMENTS

This module was inspired both by Grape and L<Kelp>,
which was inspired by L<Dancer>, which in its turn was inspired by Sinatra.

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
