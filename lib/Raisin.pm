#!perl
#PODNAME: Raisin
#ABSTRACT: A REST API microframework for Perl.

use strict;
use warnings;

package Raisin;

use Carp qw(croak carp longmess);
use HTTP::Status qw(:constants);
use Plack::Response;
use Plack::Util;

use Raisin::Request;
use Raisin::Routes;
use Raisin::Util;

use Raisin::Middleware::Formatter;
use Raisin::Encoder;
use Raisin::Decoder;

use Plack::Util::Accessor qw(
    middleware
    mounted
    routes

    decoder
    encoder
);

sub new {
    my ($class, %args) = @_;

    my $self = bless { %args }, $class;

    $self->middleware({});
    $self->mounted([]);
    $self->routes(Raisin::Routes->new);

    $self->decoder(Raisin::Decoder->new);
    $self->encoder(Raisin::Encoder->new);

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
sub add_route {
    my ($self, %params) = @_;
    $self->routes->add(%params);
}

# Resource description
sub resource_desc {
    my ($self, $ns, $desc) = @_;
    $self->{resource_desc}{$ns} = $desc if $desc;
    $self->{resource_desc}{$ns};
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
    my $psgi = sub { $self->psgi(@_) };

    $self->{allowed_methods} = $self->generate_allowed_methods;

    # Add middleware
    for my $class (keys %{ $self->{middleware} }) {
        # Make sure the middleware was not already loaded
        next if $self->{_loaded_middleware}->{$class}++;

        my $mw = Plack::Util::load_class($class, 'Plack::Middleware');
        my $args = $self->{middleware}{$class};
        $psgi = $mw->wrap($psgi, @$args);
    }

    $psgi = Raisin::Middleware::Formatter->wrap(
        $psgi,
        default_format => $self->default_format,
        format => $self->format,
        decoder => $self->decoder,
        encoder => $self->encoder,
        raisin => $self,
    );

    # load fallback logger (Raisin::Logger)
    $self->load_plugin('Logger', fallback => 1);

    return $psgi;
}

sub generate_allowed_methods {
    my $self = shift;

    my %allowed_methods_by_endpoint;

    # `options` for each `path`
    for my $path (keys %{ $self->routes->list }) {
        my $methods = join ', ',
            sort(keys(%{ $self->routes->list->{$path} }), 'OPTIONS');

        $self->add_route(
            method => 'OPTIONS',
            path => $path,
            code => sub {
                $self->res->headers([Allow => $methods]);
                undef;
            },
        );

        $allowed_methods_by_endpoint{$path} = $methods;
    }

    \%allowed_methods_by_endpoint;
}

sub psgi {
    my ($self, $env) = @_;

    # New for each response
    my $req = $self->req(Raisin::Request->new($env));
    my $res = $self->res(Plack::Response->new);

    # Generate API description
    if ($self->can('swagger_build_spec')) {
        $self->swagger_build_spec;
    }

    my $ret = eval {
        $self->hook('before')->($self);

        # Find a route
        my $route = $self->routes->find($req->method, $req->path);
        # The requested path exists but requested method not
        if (!$route && $self->{allowed_methods}{ $req->path }) {
            $res->status(HTTP_METHOD_NOT_ALLOWED);
            return $res->finalize;
        }
        # Nothing found
        elsif (!$route) {
            $res->status(HTTP_NOT_FOUND);
            return $res->finalize;
        }

        my $code = $route->code;
        if (!$code || ($code && ref($code) ne 'CODE')) {
            $self->log(error => "route ${ \$req->path } returns nothing or not CODE");

            $res->status(HTTP_INTERNAL_SERVER_ERROR);
            $res->body('Internal error');

            return $res->finalize;
        }

        $self->hook('before_validation')->($self);

        # Validation and coercion of declared params
        if (!$req->prepare_params($route->params, $route->named)) {
            $res->status(HTTP_BAD_REQUEST);
            $res->body('Invalid Parameters');
            return $res->finalize;
        }

        $self->hook('after_validation')->($self);

        # Evaluate an endpoint
        my $data = $code->($req->declared_params);
        if (defined $data) {
            # Delayed response
            return $data if ref($data) eq 'CODE';

            $res->body($data);
        }

        $self->hook('after')->($self);

        1;
    } or do {
        my ($e) = longmess($@);
        $self->log(error => $e);

        my $msg = $ENV{PLACK_ENV}
            && $ENV{PLACK_ENV} eq 'deployment' ? 'Internal Error' : $e;

        $res->status(HTTP_INTERNAL_SERVER_ERROR);
        $res->body($msg);
    };

    if (ref($ret) eq 'CODE') {
        return $ret;
    }

    $self->finalize;
}

# Finalize response
sub before_finalize {
    my $self = shift;

    $self->res->status(HTTP_OK) unless $self->res->status;
    $self->res->header('X-Framework' => 'Raisin ' . __PACKAGE__->VERSION);

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
sub default_format {
    my ($self, $format) = @_;

    if ($format) {
        $self->{default_format} = $format;
    }

    $self->{default_format} || 'yaml';
}

sub format {
    my ($self, $format) = @_;

    if ($format) {
        my @decoders = keys %{ $self->decoder->all };

        if (grep { lc($format) eq $_ } @decoders) {
            $self->{format} = lc $format;
            $self->default_format(lc $format);
        }
        else {
            carp 'Invalid format, choose one of: ', join(', ', @decoders);
        }
    }

    $self->{format};
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

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Raisin is a REST API microframework for Perl.
It's designed to run on Plack, providing a simple DSL to develop RESTful APIs easily.
It was inspired by L<Grape|https://github.com/intridea/grape>.

=for HTML
<a href="https://cloud.drone.io/khrt/Raisin"><img src="https://cloud.drone.io/api/badges/khrt/Raisin/status.svg" /></a>
<a href="http://badge.fury.io/pl/Raisin"><img src="https://badge.fury.io/pl/Raisin.svg" alt="CPAN version" height="18"></a>

=head1 FUNCTIONS

=head2 API DESCRIPTION

=head3 resource

Adds a route to an application.

    resource user => sub { ... };

=head3 route_param

Defines a route parameter as a resource C<id> which can be anything if type
isn't specified for it.

    route_param id => sub { ... };

Raisin allows you to nest C<route_param>:

    params requires => { name => 'id', type => Int };
    route_param id => sub {
        get sub { ... };

        params requires => { name => 'sub_id', type => Int };
        route_param sub_id => sub {
            ...
        };
    };

=head3 del, get, patch, post, put

Shortcuts to add a C<route> restricted to the corresponding HTTP method.

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

=head3 desc

Adds a description to C<resource> or any of the HTTP methods.
Useful for OpenAPI as it's shown there as a description of an action.

    desc 'Some long explanation about an action';
    put sub { ... };

    desc 'Some exaplanation about a group of actions',
    resource => 'user' => sub { ... }

=head3 summary

Same as L</desc> but shorter.

    summary 'Some summary';
    put sub { ... };

=head3 tags

Tags can be used for logical grouping of operations by resources
or any other qualifier. Using in API description.

    tags 'delete', 'user';
    delete sub { ... };

By default tags are added automatically based on it's namespace but you always
can overwrite it using the function.

=head3 entity

Describes response object which will be used to generate OpenAPI description.

    entity 'MusicApp::Entity::Album';
    get {
        my $albums = $schema->resultset('Album');
        present data => $albums, with => 'MusicApp::Entity::Album';
    };


=head3 params

Defines validations and coercion options for your parameters.
Can be applied to any HTTP method and/or L</route_param> to describe parameters.

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

For more see L<Raisin/Validation-and-coercion>.

=head3 api_default_format

Specifies default API format mode when formatter isn't specified by API user.
E.g. if URI is asked without an extension (C<json>, C<yaml>) or C<Accept> header
isn't specified the default format will be used.

Default value: C<YAML>.

    api_default_format 'json';

See also L<Raisin/API-FORMATS>.

=head3 api_format

Restricts API to use only specified formatter to serialize and deserialize data.

Already exists L<Raisin::Encoder::JSON>, L<Raisin::Encoder::YAML>,
and L<Raisin::Encoder::Text>, but you can always register your own
using L</register_encoder>.

    api_format 'json';

See also L<Raisin/API-FORMATS>.

=head3 api_version

Sets up an API version header.

    api_version 1.23;

=head3 plugin

Loads a Raisin module. A module options may be specified after the module name.
Compatible with L<Kelp> modules.

    plugin 'Swagger';

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

=head3 register_decoder

Registers a third-party parser (decoder).

    register_decoder(xml => 'My::Parser::XML');

See also L<Raisin::Decoder>.

=head3 register_encoder

Registers a third-party formatter (encoder).

    register_encoder(xml => 'My::Formatter::XML');

See also L<Raisin::Encoder>.

=head3 run

Returns the C<PSGI> application.

=head2 CONTROLLER

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

=head3 include_missing

Returns all declared parameters even if there is no value for a param.

See L<Raisin/Declared-parameters>.

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

=head1 ALLOWED METHODS

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

=head1 PARAMETERS

Request parameters are available through the C<params> C<HASH>. This includes
GET, POST and PUT parameters, along with any named parameters you specify in
your route strings.

Parameters are automatically populated from the request body
on C<POST> and C<PUT> for form input, C<JSON> and C<YAML> content-types.

The request:

    curl localhost:5000/data -H Content-Type:application/json -d '{"id": "14"}'

The Raisin endpoint:

    post data => sub { param('id') };

Multipart C<POST>s and C<PUT>s are supported as well.

In the case of conflict between either of:

=over

=item * path parameters;

=item * GET, POST and PUT parameters;

=item * contents of request body on POST and PUT;

=back

Path parameters have precedence.

Query string and body parameters will be merged (see L<Plack::Request/parameters>)

=head2 Declared parameters

Raisin allows you to access only the parameters that have been declared by you in
L<Raisin/params> block.

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
If you want to return all parameters you can use the C<include_missing> function.

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

=head2 Validation and coercion

You can define validations and coercion options for your parameters using a
L<Raisin/params> block.

Parameters can C<requires> value or can be C<optional>.
C<optional> parameters can have default value.

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

=over

=item * name

=item * type

=item * default

=item * desc

=item * regex

=item * in

=back

=head2 Nested Parameters

=head3 Hash

Use a keyword C<group> to define a group of parameters which is enclosed to
the parent C<HashRef> parameter.

    params(
        requires('name', type => HashRef, group {
            requires('first_name', type => Str),
            requires('last_name', type => Str),
        })
    )

=head3 Array

Use C<ArrayRef[*]> types from your compatible type library to define arrays.

    requires('list', type => ArrayRef[Int], desc => 'List of integers')

=head2 Types

Raisin supports Moo(se)-compatible type constraint so you can use any of the
L<Moose>, L<Moo> or L<Type::Tiny> type constraints.

By default L<Raisin> depends on L<Type::Tiny> and it's L<Types::Standard> type
contraint library.

You can create your own types as well.
See L<Type::Tiny::Manual> and L<Moose::Manual::Types>.

=head1 HOOKS

Those blocks can be executed before or/and after every API call, using
C<before>, C<after>, C<before_validation> and C<after_validation>.

Callbacks execute in the following order:

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

Steps C<after_validation> and C<after> are executed only if validation succeeds.

Every callback has only one argument as an input parameter which is L<Raisin>
object. For more information of available methods see L<Raisin/CONTROLLER>.

=head1 API FORMATS

By default, Raisin supports C<YAML>, C<JSON>, and C<TEXT> content types.
Default format is C<YAML>.

Response format can be determined by C<Accept header> or C<route extension>.

Serialization takes place automatically. So, you do not have to call
C<encode_json> in each C<JSON> API implementation.

Your API can declare to support only one serializator by using L<Raisin/api_format>.

Custom formatters for existing and additional types can be defined with a
L<Raisin::Encoder>/L<Raisin::Decoder>.

=over

=item JSON

Call C<JSON::encode_json> and C<JSON::decode_json>.

=item YAML

Call C<YAML::Dump> and C<YAML::Load>.

=item Text

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

The plugin registers a C<log> subroutine to L<Raisin>. Below are examples of
how to use it.

    app->log(debug => 'Debug!');
    app->log(warn => 'Warn!');
    app->log(error => 'Error!');

C<app> is a L<Raisin> instance, so you can use C<$self> instead of C<app> where
it is possible.

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

=head2 OpenAPI/Swagger

L<Swagger|http://swagger.io> compatible API documentations.

    plugin 'Swagger';

Documentation will be available on C<http://E<lt>urlE<gt>/swagger.json> URL.
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

See also L<Plack::Builder>, L<Plack::App::URLMap>.

=head1 EXAMPLES

Raisin comes with three instance in I<example> directory:

=over

=item pod-synopsis-app

Basic example.

=item music-app

Shows the possibility of using L<Raisin/present> with L<DBIx::Class>
and L<Rose::DB::Object>.

=item sample-app

Shows an example of complex application.

=back

=head1 ROADMAP

=over

=item * Versioning support;

=item * Mount API's in any place of C<resource> block;

=back

=head1 GITHUB

L<https://github.com/khrt/Raisin|https://github.com/khrt/Raisin>

=head1 ACKNOWLEDGEMENTS

This module was inspired both by Grape and L<Kelp>,
which was inspired by L<Dancer>, which in its turn was inspired by Sinatra.

=cut
