package Raisin;

use strict;
use warnings;
use feature ':5.12';

use Carp;
use DDP; # XXX
#use Plack::Builder;
use Plack::Util;

use Raisin::Request;
use Raisin::Response;
use Raisin::Routes;

our $VERSION = '0.1';
our $CODENAME = 'Cabernet Sauvignon';

sub new {
    my ($class, %args) = @_;
    my $self = bless { %args }, $class;

    $self->{routes} = Raisin::Routes->new;
    $self->{mounted} = [];

    $self;
}

sub load_plugin {
    my ($self, $name, @args) = @_;
    return if $self->{loaded_plugins}{$name};

    my $class = Plack::Util::load_class($name, 'Raisin::Plugin');
    my $module = $self->{loaded_plugins}{$name} = $class->new($self);

    $module->build(@args);
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
sub mount_package {
    my ($self, $package) = @_;
    push @{ $self->{mounted} }, $package;
    $package = Plack::Util::load_class($package);
}

sub run {
    my $self = shift;
    my $app = sub { $self->psgi(@_) };

    # Add middleware
#    if (defined(my $middleware = $self->config('middleware'))) {
#        for my $class (@$middleware) {
#
#            # Make sure the middleware was not already loaded
#            next if $self->{_loaded_middleware}->{$class}++;
#
#            my $mw = Plack::Util::load_class($class, 'Plack::Middleware');
#            my $args = $self->config("middleware_init.$class") // {};
#            $app = $mw->wrap($app, %$args);
#        }
#    }

    return $app;
}

sub psgi {
    my ($self, $env) = @_;

    # Diffrent for each response
    my $req = $self->req(Raisin::Request->new($env));
    my $res = $self->res(Raisin::Response->new($self));

    # TODO Check incoming content type
#    if (my $content_type = $self->default_content_type) {
#        if (!$req->content_type or $req->content_type ne $content_type) {
#            $res->render_error(409, 'Invalid format!');
#            return $self->res->finalize;
#        }
#    }

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
            my $code = $route->code; # endpoint

            if (!$code || (ref($code) && ref($code) ne 'CODE')) {
                die 'Invalid endpoint for ' . $req->path;
            }

            # Log
            if ($self->can('logger')) {
                $self->logger(info => $req->method . ' ' . $route->path);
            }

            # HOOK Before validation
            $self->hook('before_validation')->($self);

            # Load params
            my $params = $req->parameters->mixed;
            my $named = $route->named;
#say '-' . ' PATH PARAMS -' x 3;
#p $named;
#say '*' . ' <--' x 3;

            # Validation # TODO BROKEN
            $req->set_declared_params($route->params);
            $req->set_named_params($route->named);

            # What TODO if parameters is invalid?
            if (not $req->validate_params) {
                warn '* ' . 'INVALID PARAMS! ' x 5;
                $res->render_error(400, 'Invalid params!');
                last;
            }

            my $declared_params = $req->declared_params;
#say '-' . ' DECLARED PARAMS -' x 3;
#p %declared_params;
#say ' =' x 3;

            # HOOK After validation
            $self->hook('after_validation')->($self);

            # Eval code
            my $data = $code->($declared_params);

            # Format plugins
            if ($self->can('serialize')) {
                $data = $self->serialize($data);
            }

            # Set default content type
            $res->content_type($self->default_content_type);

            # Bridge?
#        if ($route->bridge) {
#            if (!$data) {
#                $res->render_401 if not $res->rendered;
#                last;
#            }
#            next;
#        }

            if (defined $data) {
                # Handle delayed response
                return $data if ref($data) eq 'CODE'; # TODO check delayed responses
                $res->render($data) if not $res->rendered;
            }

            # HOOK After
            $self->hook('after')->($self);
        }

        if (!$res->rendered) {
            croak 'Nothing rendered!';
        }
    };

    if (my $e = $@) {
        #$e = longmess($e);
        $res->render_500($e);
    }

    $self->finalize;
}

# Finalize response
sub before_finalize {
    my $self = shift;
    $self->res->header('X-Framework' => "Raisin $VERSION");
}

sub finalize {
    my $self = shift;
    $self->before_finalize;
    $self->res->finalize;
}

# Application defaults
sub api_format {
    my ($self, $name) = @_;
    $name = $name =~ /\+/ ? $name : "Format::$name";
    $self->load_plugin($name);
}

sub default_content_type { shift->{default_content_type} || 'text/plain' }

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

sub params { shift->req->parameters }

sub session {
    my $self = shift;

    if (not $self->req->env->{'psgix.session'}) {
        croak "No Session middleware wrapped";
    }

    $self->req->session;
}

1;

=head1 NAME

Raisin - A REST-like API micro-framework for Perl.

=head1 SYNOPSYS

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

=head1 DESCRIPTION

Raisin is a REST-like API micro-framework for Perl.
It's designed to run on Plack, providing a simple DSL
to easily develop RESTful APIs.

It's a clone of L<Grape|https://github.com/intridea/grape>.

=head1 KEYWORDS

=head2 namespace

    namespace user => sub { ... };

=head2 route_param

    route_param id => $Raisin::Types::Integer, sub { ... };

=head2 delete, get, post, put

These are shortcuts to C<route> restricted to the corresponding HTTP method.

    get sub { 'GET' };

    get params => [
        required => ['id', $Raisin::Types::Integer],
        optional => ['key', $Raisin::Types::String],
    ],
    sub { 'GET' };

=head2 req

An alias for C<$self-E<gt>req>, this provides quick access to the
L<Raisin::Request> object for the current route.

=head2 res

An alias for C<$self-E<gt>res>, this provides quick access to the
L<Raisin::Response> object for the current route.

=head2 params

An alias for C<$self-E<gt>params> that gets the GET and POST parameters.
When used with no arguments, it will return an array with the names of all http
parameters. Otherwise, it will return the value of the requested http parameter.

=head2 session

An alias for C<$self-E<gt>session> that returns (optional) psgix.session hash.
When it exists, you can retrieve and store per-session data from and to this hash.

=head2 plugin

Loads a Raisin module. The module options may be specified after the module name.
Compatible with L<Kelp> modules.

    plugin 'Logger' => outputs => [['Screen', min_level => 'debug']];

=head2 api_format

Load a C<Raisin::Plugin::Format> plugin. Already exists L<Raisin::Plugin::Format::JSON>
and L<Raisin::Plugin::Format::YAML>.

    api_format 'JSON';

=head2 mount

Mount multiple API implementations inside another one.  These don't have to be
different versions, but may be components of the same API.

    mount 'RApp::User';
    mount 'RApp::Host';

=head2 run, new

Creates and returns a PSGI ready subroutine, and makes the app ready for C<Plack>.

=head1 ROUTING

about routing

=head1 PARAMETERS

    get params => [
        optional => ['start', $Raisin::Types::Integer, 0],
        optional => ['count', $Raisin::Types::Integer, 10],
        required => ['email', $Raisin::Types::String, undef, qr/[^@]@[^.].\w+/],
    ],

=head2 Declared params

required/optional => [name, type, default, regex]

=head2 Types

See L<Raisin::Types>

=head1 HOOKS

C<before>, C<before_validation>, C<after_validation>, C<after>

=head1 ADDING MIDDLEWARE

You can easily add middleware to your application using C<middleware> keyword.

=head1 PLUGINS

See L<Raisin::Plugin>

=head1 DEPLOYING

Plack::Builder ...

=head1 GitHub

https://github.com/khrt/Raisin

=head1 AUTHOR

Artur Khabibullin - khrt <at> ya.ru

=head1 ACKNOWLEDGEMENTS

This module's interface was inspired by L<Kelp>, which was inspired L<Dancer>,
which in its turn was inspired by Sinatra, so Viva La Open Source!

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
