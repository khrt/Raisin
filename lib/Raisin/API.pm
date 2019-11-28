#!perl
#PODNAME: Raisin::API
#ABSTACT: Provides Raisin DSL.

use strict;
use warnings;

package Raisin::API;

use parent 'Exporter';

use Carp;
use Hash::Merge qw(merge);

use Raisin;
use Raisin::Entity;
# use Raisin::Util qw(merge);

my @APP_CONF_METHODS = qw(
    app
    api_default_format api_format api_version
    middleware mount plugin
    register_decoder register_encoder
);
my @APP_EXEC_METHODS = qw(new run);
my @APP_METHODS = qw(req res param include_missing session present error);
my @HOOKS_METHODS = qw(before before_validation after_validation after);
my @HTTP_METHODS = qw(del get head options patch post put);
my @ROUTES_METHODS =
    qw(resource namespace route_param params requires optional group);
my @SWAGGER_MERTHODS = qw(desc entity summary tags produces);

our @EXPORT = (
    @APP_CONF_METHODS,
    @APP_EXEC_METHODS,
    @APP_METHODS,
    @HOOKS_METHODS,
    @HTTP_METHODS,
    @ROUTES_METHODS,
    @SWAGGER_MERTHODS,
);

my %SETTINGS = ();
my @NS = ('');

my $app;

sub import {
    my $class = shift;
    $class->export_to_level(1, $class, @_);

    strict->import;
    warnings->import;

    my $caller = caller;
    $app ||= Raisin->new(caller => $caller);
}

sub app { $app }

#
# Execution
#
sub new { app->run }
sub run { app->run }

#
# Compile
#
sub mount { app->mount_package(@_) }
sub middleware { app->add_middleware(@_) }

#
# Hooks
#
sub before { app->add_hook('before', shift) }
sub before_validation { app->add_hook('before_validation', shift) }

sub after_validation { app->add_hook('after_validation', shift) }
sub after { app->add_hook('after', shift) }

#
# Resource
#
sub resource {
    my ($name, $code, @args) = @_;
    if (scalar(@args) % 2) {
        croak "Odd-sized hash supplied to resource(). Is the previous resource missing a semicolon?";
    }
    my %args = @args;

    if ($name) {
        $name =~ s{^/}{}msx;
        push @NS, $name;

        if ($SETTINGS{desc}) {
            app->resource_desc($NS[-1], delete $SETTINGS{desc});
        }

        my %prev_settings = %SETTINGS;
        Hash::Merge::set_clone_behavior(undef);
        %SETTINGS = %{ merge(\%SETTINGS, \%args) };

        # Going deeper
        $code->();

        pop @NS;
        %SETTINGS = ();
        %SETTINGS = %prev_settings;
    }

    (join '/', @NS) || '/';
}
sub namespace { resource(@_) }

sub route_param {
    my ($param, $code) = @_;
    resource(":$param", $code, named => delete $SETTINGS{params});
}

#
# Serialization
#
sub register_decoder {
    my ($format, $class) = @_;
    app->decoder->register($format => $class);
}

sub register_encoder {
    my ($format, $class) = @_;
    app->encoder->register($format => $class);
}

#
# Actions
#
sub del     { _add_route('delete', @_) }
sub get     { _add_route('get', @_) }
sub head    { _add_route('head', @_) }
sub options { _add_route('options', @_) }
sub patch   { _add_route('patch', @_) }
sub post    { _add_route('post', @_) }
sub put     { _add_route('put', @_) }

sub params { $SETTINGS{params} = \@_ }

sub requires { (requires => { name => @_ }) }
sub optional { (optional => { name => @_ }) }

sub group(&) { (encloses => [shift->()]) }

# Swagger
sub desc    { $SETTINGS{desc} = shift }
sub entity  { $SETTINGS{entity} = shift }
sub summary { $SETTINGS{summary} = shift }
sub tags    { $SETTINGS{tags} = \@_ }
sub produces {$SETTINGS{produces} = shift }

sub _add_route {
    my @params = @_;

    my $code = pop @params;

    my ($method, $path) = @params;
    my $r = resource();
    if ($r eq '/' && $path) {
        $path = $r . $path;
    }
    else {
        $path = $r . ($path ? "/$path" : '');
    }

    app->add_route(
        code    => $code,
        method  => $method,
        path    => $path,
        params  => delete $SETTINGS{params},

        desc    => delete $SETTINGS{desc},
        entity  => delete $SETTINGS{entity},
        summary => delete $SETTINGS{summary},
        tags    => delete $SETTINGS{tags},
        produces   => delete $SETTINGS{produces},

        %SETTINGS,
    );

    join '/', @NS;
}

#
# Request and Response shortcuts
#
sub req { app->req }
sub res { app->res }
sub param {
    my $name = shift;
    return app->req->raisin_parameters->{$name} if $name;
    app->req->raisin_parameters;
}
sub session { app->session(@_) }

sub present {
    my ($key, $data, %params) = @_;

    my $entity = $params{with} || 'Raisin::Entity::Default';
    my $value = Raisin::Entity->compile($entity, $data);

    my $body = res->body || {};
    my $representation = { $key => $value, %$body };

    res->body($representation);

    return;
}

sub include_missing {
    my $p = shift;
    # TODO: replace app->req->{'raisin.declared'}, if it is possible, to app->route->params
    my %pp = map { $_->name, $p->{ $_->name } } @{ app->req->{'raisin.declared'} };
    \%pp;
}

#
# System
#
sub plugin { app->load_plugin(@_) }

sub api_default_format { app->default_format(@_) }
sub api_format { app->format(@_) }

# TODO:
# prepend a resource with a version number
# http://example.com/api/1
sub api_version { app->api_version(@_) }

#
# Render
#
sub error {
    my ($code, $message) = @_;
    app->res->status($code);
    app->res->body($message);
}

1;

__END__

=head1 DESCRIPTION

See L<Raisin>.

=cut
