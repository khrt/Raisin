package Raisin;

use strict;
use warnings;
use feature ':5.12';

use Carp;

use Raisin::Request;
use Raisin::Response;

our $VERSION = '0.1';
our $CODENAME = 'Cabernet Sauvignon';

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;
    return $self;
}


sub psgi {
    my ($self, $env) = @_;

    # Diffrent for each response
    my $req = $self->req(Raisin::Request->new($self, $env)); # TODO Raisin::Request?
    my $res = $self->res(Raisin::Response->new($self));


    ###
use Data::Dumper;

my $code = $self->{routes}{$req->method . $req->path}[-1];
eval { say Dumper $code->() };

warn $res->status;
warn $res->json;

die $@;
    ###

    # Find route
    my $route = $self->routes->match($req->method, $req->path);

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
}

sub session {
    my $self = shift;

    if (not $self->req->env->{'psgix.session'}) {
        croak "No Session middleware wrapped";
    }

    $self->req->session;
}

#
sub add_route {
    my ($self, $method, $path, @args) = @_;
    say uc($method) . "\t" . $path;


    $self->{routes}{"$method$path"} = \@args;
}

1;
