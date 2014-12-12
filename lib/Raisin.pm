package Raisin;

use strict;
use warnings;

use Carp qw(croak carp longmess);
use Plack::Util;

use Raisin::Request;
use Raisin::Response;
use Raisin::Routes;
use Raisin::Util;

our $VERSION = '0.55';

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
    my ($self, $path, $desc) = @_;
    $self->{resource_desc}{$path} = $desc if $desc;
    $self->{resource_desc}{$path};
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
    if ($self->can('build_api_spec')) {
        $self->build_api_spec;
    }

    eval {
        $self->hook('before')->($self);

        # Find a route
        my $route = $self->routes->find($req->method, $req->path);

        if (!$route) {
            $res->render_404;
            return $res->finalize;
        }

        if ($self->api_format && (my $type = $req->accept_format)) {
            if ($type ne $self->api_format) {
                $self->log(error => 'Invalid accept header');
                $res->render_error(406, 'Invalid accept header');
                return $res->finalize;
            }
        }

        my $code = $route->code;
        if (!$code || ($code && ref($code) ne 'CODE')) {
            $res->render_500('Invalid endpoint for ' . $req->path);
            return $res->finalize;
        }

        $self->hook('before_validation')->($self);

        # Validation and coercion of a declared params
        if (not $req->prepare_params($route->params, $route->named)) {
            $res->render_error(400, 'Invalid params!');
            return $res->finalize;
        }

        $self->hook('after_validation')->($self);

        # Eval user endpoint
        my $data = $code->($req->declared_params);
        if (defined $data) {
            # TODO: delayed responses are untested
            return $data if ref($data) eq 'CODE';
            $res->body($data);
        }

        if (!$res->rendered) {
            my $format = $route->format || $req->header('Accept');
            $res->format($format);
            $res->render;
        }

        $self->hook('after')->($self);

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

=encoding utf8

=head1 NAME

Raisin - a REST API micro framework for Perl.

=head1 SYNOPSIS

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

    desc 'Actions on users';
    resource user => sub {
        desc 'List users';
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

        desc 'List all users at once';
        get 'all' => sub {
            my @users
                = map { { id => $_, %{ $USERS{$_} } } }
                  sort { $a <=> $b } keys %USERS;
            { data => \@users }
        };

        desc 'Create new user';
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
        params(
            requires => { name => 'id', type => Int, desc => 'User ID' },
        );
        route_param 'id' => sub {
            desc 'Show user';
            get sub {
                my $params = shift;
                $USERS{ $params->{id} };
            };

            desc 'Delete user';
            del sub {
                my $params = shift;
                { success => delete $USERS{ $params->{id} } };
            };
        };
    };

    resource echo => sub {
        params(
            optional => { name => 'data0', type => Any, default => "ёй" },
        );
        get sub { shift };

        desc 'NOP';
        get nop => sub { };
    };

    run;

=head1 DESCRIPTION

Raisin is a REST API micro framework for Perl.
It's designed to run on Plack, providing a simple DSL to easily develop RESTful APIs.
It was inspired by L<Grape|https://github.com/intridea/grape>.

=for HTML <a href="https://travis-ci.org/khrt/Raisin"><img src="https://travis-ci.org/khrt/Raisin.svg?branch=master"></a>

=head1 FUNCTIONS

=head2 API DESCRIPTION

=head3 resource

Adds a route to an application.

    resource user => sub { ... };

=head3 route_param

Define a route parameter as a namespace C<route_param>.

    route_param id => sub { ... };

=head3 del, get, patch, post, put

Shortcuts to add a C<route> restricted to the corresponding HTTP method.

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

=head3 desc

Can be applied to C<resource> or any of the HTTP method to add a description
for an operation or for a resource.

    desc 'Some action';
    put sub { ... };

    desc 'Some operations group',
    resource => 'user' => sub { ... }

=head3 params

Here you can define validations and coercion options for your parameters.
Can be applied to any HTTP method and/or C<route_param> to describe parameters.

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

For more see L<Raisin/Validation-and-coercion>.

=head3 api_default_format

Specifies default API format mode when formatter doesn't specified by API user.
E.g. URI is asked without an extension (C<json>, C<yaml>) or C<Accept> header
isn't specified.

Default value: C<YAML>.

    api_default_format 'json';

See also L<Raisin/API-FORMATS>.

=head3 api_format

Restricts API to use only specified formatter to serialize and deserialize data.

Already exists L<Raisin::Plugin::Format::JSON> and L<Raisin::Plugin::Format::YAML>.

    api_format 'json';

See also L<Raisin/API-FORMATS>.

=head3 api_version

Sets up an API version header.

    api_version 1.23;

=head3 plugin

Loads a Raisin module. A module options may be specified after the module name.
Compatible with L<Kelp> modules.

    plugin 'Swagger', enable => 'CORS';

=head3 middleware

Adds a middleware to your application.

    middleware '+Plack::Middleware::Session' => { store => 'File' };
    middleware '+Plack::Middleware::ContentLength';
    middleware 'Runtime'; # will be loaded Plack::Middleware::Runtime

=head3 mount

Mounts multiple API implementations inside another one.
These don't have to be different versions, but may be components of the same API.

In C<RaisinApp.pm>:

    package RaisinApp;

    use Raisin::API;

    api_format 'json';

    mount 'RaisinApp::User';
    mount 'RaisinApp::Host';

    1;

=head3 run

Returns the C<PSGI> application.

=head2 INSIDE ROUTE

=head3 req

Provides quick access to the L<Raisin::Request> object for the current route.

Use C<req> to get access to request headers, params, etc.

    use DDP;
    p req->headers;
    p req->params;

    say req->header('X-Header');

See also L<Plack::Request>.

=head3 res

Provides quick access to the L<Raisin::Response> object for the current route.

Use C<res> to set up response parameters.

    res->status(403);
    res->headers(['X-Application' => 'Raisin Application']);

See also L<Plack::Response>.

=head3 param

Returns request parameters.
Without an argument will return an array of all input parameters.
Otherwise it will return the value of the requested parameter.

Returns L<Hash::MultiValue> object.

    say param('key'); # -> value
    say param(); # -> { key => 'value', foo => 'bar' }

=head3 session

Returns C<psgix.session> hash. When it exists, you can retrieve and store
per-session data.

    # store param
    session->{hello} = 'World!';

    # read param
    say session->{name};

=head3 present

Raisin hash a built-in C<present> method, which accepts two arguments: an
object to be presented and an options associated with it. The options hash may
include C<with> key, which is defined the entity to expose. See L<Raisin::Entity>.

    my $artists = $schema->resultset('Artist');

    present data => $artists, with => 'MusicApp::Entity::Artist';
    present count => $artists->count;

L<Raisin::Entity> supports L<DBIx::Class> and L<Rose::DB::Object>.

For details see examples in I<examples/music-app> and L<Raisin::Entity>.

=head1 PARAMETERS

A request parameters are available through the C<params> C<HASH>. This includes
GET, POST and PUT parameters, along with any named parameters you specify in
your route strings.

Parameters are automatically populated from the request body
on C<POST> and C<PUT> for form input, C<JSON> and C<YAML> content-types.

The request:

    curl -d '{"id": "14"}' 'http://localhost:5000/data' -H Content-Type:application/json -v

The Raisin endpoint:

    post data => sub {
        my $params = shift;
        $params{id};
    }

Multipart C<POST>s and C<PUT>s are supported as well.

In the case of conflict between either of:

=over

=item * route string parameters;

=item * GET, POST and PUT parameters;

=item * contents of request body on POST and PUT;

=back

route string parameters will have precedence.

Query string and body parameters will be merged (see L<Plack::Request/parameters>)

=head2 Validation and coercion

You can define validations and coercion options for your parameters using a
L<Raisin/params> block.

Parameters can C<requires> a value and can be an C<optional>.
C<optional> parameters can have a default value.

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

=over

=item * name

=item * type

=item * default

=item * desc

=item * regex

=back

=head2 Types

Raisin supports Moo(se)-compatible type constraint so you can use any of the
L<Moose>, L<Moo> or L<Type::Tiny> type constraints.

By default L<Raisin> depends on L<Type::Tiny> and it's L<Types::Standard> type
contraint library.

You can create your own types as well.
See L<Type::Tiny::Manual> and L<Moose::Manual::Types>.

=head1 HOOKS

This blocks can be executed before or/and after every API call, using
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

Raisin has a built-in logger and supports for C<Log::Dispatch>.
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

=head2 Swagger

L<Swagger|https://github.com/wordnik/swagger-core> compatible API documentations.

    plugin 'Swagger';

Documentation will be available on C<http://E<lt>urlE<gt>/api-docs> URL.
So you can use this URL in Swagger UI.

See L<Raisin::Plugin::Swagger>.

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

    $ plackup -E deployment -s Starman app.psgi

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

Raisin comes with three instance in I<example> directory:

=over

=item pod-synopsis-app

Basic instance which is used in synopsis.

=item music-app

Shows the possibility of using L<Raisin/present> with L<DBIx::Class>
and L<Rose::DB::Object>.

=item sample-app

Shows an example of complex application.

=back

=head1 ROADMAP

=over

=item * Upgrade Swagger to L<2.0|https://github.com/wordnik/swagger-spec/blob/master/versions/2.0.md> and make support for L<Raisin::Entity/documentation>;

=item * Endpoint's hooks: C<after>, C<before>;

=item * Mount API's in any place of C<resource> block;

=item * C<declared> keyword which should be applicable to C<param> and supports for C<missing> keyword;

=back

=head1 GITHUB

L<https://github.com/khrt/Raisin|https://github.com/khrt/Raisin>

=head1 ACKNOWLEDGEMENTS

This module was inspired both by Grape and L<Kelp>,
which was inspired by L<Dancer>, which in its turn was inspired by Sinatra.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
