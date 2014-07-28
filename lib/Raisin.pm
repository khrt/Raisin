package Raisin;

use strict;
use warnings;

use Carp qw(croak carp longmess);
use Plack::Util;

use Raisin::Request;
use Raisin::Response;
use Raisin::Routes;
use Raisin::Util;

our $VERSION = '0.4003';

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
sub add_route {
    my ($self, %params) = @_;
    $params{api_format} = $self->api_format if $self->api_format;
    $self->routes->add(%params);
}

# Resource description
sub resource_desc {
    my ($self, $resource) = @_;
    $resource =~ s#^/##msx;
    $self->{resource_desc}{$resource};
}

sub add_resource_desc {
    my ($self, %params) = @_;
    $self->{resource_desc}{ $params{resource} } = $params{desc};
}

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

    # load fallback logger (Raisin::Logger)
    $self->load_plugin('Logger', fallback => 1);

    return $app;
}

sub psgi {
    my ($self, $env) = @_;

    # Diffrent for each response
    my $req = $self->req(Raisin::Request->new($self, $env));
    my $res = $self->res(Raisin::Response->new($self));

    # Build API docs
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
            if ($self->api_format && (my $type = $req->accept_format)) {
                if ($type ne $self->api_format) {
                    $self->log(error => 'Invalid accept header');
                    $res->render_error(406, 'Invalid accept header');
                    last;
                }
            }

            # Validate code variable
            my $code = $route->code;
            if (!$code || (ref($code) && ref($code) ne 'CODE')) {
                croak 'Invalid endpoint for ' . $req->path;
            }

            # Log
            #$self->log(info => $req->method . q{ } . $route->path);

            # HOOK Before validation
            $self->hook('before_validation')->($self);

            # Populate and validate declared params
            if (not $req->prepare_params($route->params, $route->named)) {
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
            $self->log(error => 'Nothing rendered');
        }

        1;
    } or do {
        my $e = longmess($@);
        $self->log(error => $e);

        my $msg = $ENV{PLACK_ENV} eq 'deployment' ? 'Internal error' : $e;
        $res->render_500($msg);
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
sub api_default_format {
    my ($self, $format) = @_;

    if ($format) {
        $self->{api_default_format} = Raisin::Util::make_serializer_class($format);
    }

    $self->{api_default_format} || Raisin::Util::make_serializer_class('yaml');
}

sub api_format {
    my ($self, $format) = @_;

    if ($format && grep { lc($format) eq $_ } qw(json yaml)) {
        $self->{api_format} = lc $format;
        $self->api_default_format(lc $format);
    }
    elsif ($format) {
        carp "Can't use specified format. Currently supported only JSON and YAML.";
    }

    $self->{api_format};
}

sub api_version {
    my ($self, $version) = @_;
    $self->{version} = $version if $version;
    $self->{version}
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

    use strict;
    use warnings;

    use Raisin::API;
    use Types::Standard qw(Int Str);

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

    plugin 'APIDocs', enable => 'CORS';
    api_format 'json';

    desc 'Actions on users',
    resource => user => sub {
        desc 'List users',
        params => [
            optional => { name => 'start', type => Int, default => 0, desc => 'Pager (start)' },
            optional => { name => 'count', type => Int, default => 10, desc => 'Pager (count)' },
        ],
        get => sub {
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

        desc 'List all users at once',
        get => 'all' => sub {
            my @users
                = map { { id => $_, %{ $USERS{$_} } } }
                  sort { $a <=> $b } keys %USERS;
            { data => \@users }
        };

        desc 'Create new user',
        params => [
            requires => { name => 'name', type => Str, desc => 'User name' },
            requires => { name => 'password', type => Str, desc => 'User password' },
            optional => { name => 'email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email' },
        ],
        post => sub {
            my $params = shift;

            my $id = max(keys %USERS) + 1;
            $USERS{$id} = $params;

            { success => 1 }
        };

        desc 'Actions on the user',
        params => [
            requires => { name => 'id', type => Int, desc => 'User ID' },
        ],
        route_param => 'id',
        sub {
            desc 'Show user',
            get => sub {
                my $params = shift;
                $USERS{ $params->{id} };
            };

            desc 'Delete user',
            del => sub {
                my $params = shift;
                { success => delete $USERS{ $params->{id} } };
            };

            desc 'NOP',
            put => sub { 'nop' };
        };
    }

    run;

=head1 DESCRIPTION

Raisin is a REST-like API web micro-framework for Perl.
It's designed to run on Plack, providing a simple DSL to easily develop RESTful APIs.
It was inspired by L<Grape|https://github.com/intridea/grape>.

=head1 KEYWORDS

=head2 resource

Adds a route to application.

    resource user => sub { ... };

=head2 route_param

Define a route parameter as a namespace C<route_param>.

    route_param id => Int, sub { ... };

=head2 del, get, patch, post, put

It's a shortcuts to C<route> restricted to the corresponding HTTP method.

Each method can consists of this parameters:

=over

=item * desc - optional only if didn't start from C<desc> keyword, required otherwise;

=item * params - optional only if didn't start from C<params> keyword, required otherwise;

=item * path - optional;

=item * subroutine - required;

=back

Where only C<subroutine> is required.

    get sub { 'GET' };

    del 'all' => sub { 'OK' };

    params [
        requires => { name => 'id', type => Int },
        optional => { name => 'key', type => Str },
    ],
    get => sub { 'GET' };

    params [
        required => { name => 'id', type => Int },
        optional => { name => 'name', type => Str },
    ],
    desc => 'Put data',
    put => 'all' => sub {
        'PUT'
    };

=head2 desc

Can be applied to C<resource> or any of HTTP method to add description
for operation or for resource.

    desc 'Some action',
    put => sub { ... }

    desc 'Some operations group',
    resource => 'user' => sub { ... }

=head2 params

Here you can define validations and coercion options for your parameters.
Can be applied to any HTTP method to describe parameters.

    params => [
        requires => { name => 'key', type => Str }
    ],
    get => sub { ... }

For more see L<Raisin/Validation-and-coercion>.

=head2 req

An alias for C<$self-E<gt>req>, which provides quick access to the
L<Raisin::Request> object for the current route.

Use C<req> to get access to a request headers, params, etc.

    use DDP;
    p req->headers;
    p req->params;

    say req->header('X-Header');

See also L<Plack::Request>.

=head2 res

An alias for C<$self-E<gt>res>, which provides quick access to the
L<Raisin::Response> object for the current route.

Use C<res> to set up response parameters.

    res->status(403);
    res->headers(['X-Application' => 'Raisin Application']);

See also L<Plack::Response>.

=head2 param

An alias for C<$self-E<gt>params>, which returns request parameters.
Without arguments will return an array with request parameters.
Otherwise it will return the value of the requested parameter.

Returns L<Hash::MultiValue> object.

    say param('key'); # -> value
    say param(); # -> { key => 'value', foo => 'bar' }

=head2 session

An alias for C<$self-E<gt>session>, which returns C<psgix.session> hash.
When it exists, you can retrieve and store per-session data.

    # store param
    session->{hello} = 'World!';

    # read param
    say session->{name};

=head2 api_default_format

Specify default API format when formatter doesn't specified.
Default value: C<YAML>.

    api_default_format 'json';

See also L<Raisin/API-FORMATS>.

=head2 api_format

Restricts API to use only specified formatter for serialize and deserialize
data.

Already exists L<Raisin::Plugin::Format::JSON> and L<Raisin::Plugin::Format::YAML>.

    api_format 'json';

See also L<Raisin/API-FORMATS>.

=head2 api_version

Setup an API version header.

    api_version 1.23;

=head2 plugin

Loads Raisin module. A module options may be specified after a module name.
Compatible with L<Kelp> modules.

    plugin 'Logger', params => [outputs => [['Screen', min_level => 'debug']]];

=head2 middleware

Adds middleware to your application.

    middleware '+Plack::Middleware::Session' => { store => 'File' };
    middleware '+Plack::Middleware::ContentLength';
    middleware 'Runtime'; # will be loaded Plack::Middleware::Runtime

=head2 mount

Mount multiple API implementations inside another one.

In C<RaisinApp.pm>:

    package RaisinApp;

    use Raisin::API;

    api_format 'json';

    mount 'RaisinApp::User';
    mount 'RaisinApp::Host';

    1;

=head2 new, run

Creates and returns a PSGI ready subroutine, and makes the app ready for C<Plack>.

=head1 PARAMETERS

Request parameters are available through the params hash object. This includes
GET, POST and PUT parameters, along with any named parameters you specify in
your route strings.

Parameters are automatically populated from the request body on POST and PUT
for form input, C<JSON> and C<YAML> content types.

In the case of conflict between either of:

=over

=item * route string parameters;

=item * GET, POST and PUT parameters;

=item * contents of request body on POST and PUT;

=back

route string parameters will have precedence.

Query string and body parameters will be merged (see L<Plack::Request/parameters>)

=head2 Validation and coercion

You can define validations and coercion options for your parameters using a params block.

Parameters can be C<requires> and C<optional>. C<optional> parameters can have a
default value.

    params [
        requires => { name => 'name', type => Str },
        optional => { name => 'number', type => Int, default => 10 },
    ],
    get => sub {
        my $params = shift;
        "$params->{number}: $params->{name}";
    };


Available arguments:

=over

=item * name

=item * type

=item * default

=item * desc

=item * regex

=back

Optional parameters can have a default value.

=head2 Types

Raisin supports Moo(se)-compatible type constraint
so you can use any of the L<Moose>, L<Moo> or L<Type::Tiny> type constraints.

By default L<Raisin> depends on L<Type::Tiny> and it's L<Types::Standard>
type contraint library.

You can create your own types as well.
See L<Type::Tiny::Manual> and L<Moose::Manual::Types>.

=head1 HOOKS

This blocks can be executed before or after every API call, using
C<before>, C<after>, C<before_validation> and C<after_validation>.

Before and after callbacks execute in the following order:

=over

=item * before

=item * before_validation

=item * after_validation

=item * after

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

By default, Raisin supports C<YAML>, C<JSON>, and C<TEXT> content types.
Default format is C<YAML>.

Response format can be determined by C<Accept header> or C<route extension>.

Serialization takes place automatically. So, you do not have to call
C<encode_json> in each C<JSON> API implementation.

Your API can declare to support only one serializator by using L<Raisin/api_format>.

Custom formatters for existing and additional types can be defined with a
L<Raisin::Plugin::Format>.

=over

=item JSON

Call C<JSON::encode_json> and C<JSON::decode_json>.

=item YAML

Call C<YAML::Dump> and C<YAML::Load>.

=item TEXT

Call C<Data::Dumper-E<gt>Dump> if output data is not a string.

=back

The order for choosing the format is the following.

=over

=item * Use the route extension.

=item * Use the value of the C<Accept> header.

=item * Fallback to default.

=back

=head1 LOGGING

Raisin has a built-in logger and support for C<Log::Dispatch>.
You can enable it by:

    plugin 'Logger', outputs => [['Screen', min_level => 'debug']];

Or use L<Raisin::Logger> with a C<fallback> option:

    plugin 'Logger', fallback => 1;

Exports C<log> subroutine.

    log(debug => 'Debug!');
    log(warn => 'Warn!');
    log(error => 'Error!');

See L<Raisin::Plugin::Logger>.

=head1 API DOCUMENTATION

=head2 Raisin script

You can see application routes with the following command:

    $ raisin --routes examples/simple/routes.pl
      GET     /user
      GET     /user/all
      POST    /user
      GET     /user/{id}
      PUT     /user/{id}
      GET     /user/{id}/bump
      PUT     /user/{id}/bump
      GET     /failed

Verbose output with route parameters:

    $ raisin --routes --params examples/simple/routes.pl
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
