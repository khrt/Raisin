package Raisin;

use strict;
use warnings;
use feature ':5.12';

use Carp;

use Raisin::Request;
use Raisin::Response;
use Raisin::Routes;

our $VERSION = '0.1';
our $CODENAME = 'Cabernet Sauvignon';

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;

    $self->{routes} = Raisin::Routes->new;

    $self;
}

# Routes
sub routes { shift->{routes} }

sub add_route {
    my $self = shift;
    $self->routes->add(@_);
}


# Hooks
sub hook {

}

# Application
sub psgi {
    my ($self, $env) = @_;

    # Diffrent for each response
    my $req = $self->req(Raisin::Request->new($self, $env)); # TODO Raisin::Request?
    my $res = $self->res(Raisin::Response->new($self));

    ###
use Data::Dumper;
#warn Dumper $self->routes;
#my $code = $self->{fake_routes}{$req->method . $req->path}[-1];
#eval { say Dumper $code->() };
#warn $res->status;
#warn $res->json;
#die $@;
    ###

    # Find route
    my $route = $self->routes->find($req->method, $req->path);
my $code = $route->[0]->code;
warn Dumper $code->();
die 123;

    if (!@$route) {
        $res->render_404;
        return $res->finalize;
    }

    eval {

        my $code = $route->code; # endpoint

        if (!$code || (ref($code) && ref($code) ne 'CODE')) {
            die 'Invalid endpoint for ' . $req->path;
        }

        # Log

        # Get declared params
        my $declared_params = [];
        my $params = $req->declared_params($declared_params);

        # Exec `before`
        #
        # Exec `before validation`
        #

        # Validate params
        # XXX

        # Exec `after validation`
        #
        # Exec `after`
        #

        # Eval code
        my $data = $code->($req->declared_params);

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
            return $data if ref($data) eq 'CODE';

            $self->render($data) if not $res->rendered;
        }

        #if (!$self->res->rendered)
        if (!$res->rendered) {
            die 'Nothing had rendered!';
        }

        $res->finalize;
    };

    if (my $e = $@) {
        #$e = longmess($e);
        $res->res->render_500($e);
        $res->finalize;
    }
}

sub run {
    my $self = shift;
    my $app = sub { $self->psgi(@_) };

    # Middleware?
    #
    #

    return $app;
}

# Application defaults
sub format {
    # set default format: json/plain
}

sub version {
    # set version header
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

sub params {
    #$_[0]->req->query_parameters
    #$_[0]->req->body_parameters
    $_[0]->req->parameters
    # and route parameters
}

sub session {
    my $self = shift;

    if (not $self->req->env->{'psgix.session'}) {
        croak "No Session middleware wrapped";
    }

    $self->req->session;
}

1;

=pod

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
        get sub {
            map {
                my $id = $_;
                [ map { { $_ => $USERS{$id}{$_} } } keys $USERS{$id} ]
            } keys %USERS;
        };

        post params => {
            required => ['name', $Raisin::Types::String],
            required => ['password', $Raisin::Types::String],
            optional => ['email', $Raisin::Types::String, undef, qr/.+\@.+/],
        },
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
                %USERS{$params{id}};
            };
        }:
    };

    run;

=head1 DESCRIPTION

Raisin is a REST-like API micro-framework for Perl.
It's designed to run on Plack, providing a simple DSL
to easily develop RESTful APIs.

It's a clone of Grape (Ruby REST-like API micro-framework).

=over

=item * GitHub: https://github.com/khrt/Raisin

=head1 AUTHOR

Artur Khabibullin - khrt <at> ya.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
