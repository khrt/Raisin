package Raisin::API;

use strict;
use warnings;

use base 'Exporter';

use Carp;
use List::Util qw(pairs);
use Raisin;

my @APP_CONF_METHODS = qw(api_format api_version middleware mount plugin);
my @APP_EXEC_METHODS = qw(new run);
my @APP_METHODS = qw(req res param session);
my @HOOKS_METHODS = qw(before before_validation after_validation after);
my @HTTP_METHODS = qw(del get head options patch post put);
my @ROUTES_METHODS = qw(resource namespace route_param desc params);

our @EXPORT = (
    @APP_CONF_METHODS,
    @APP_EXEC_METHODS,
    @APP_METHODS,
    @HOOKS_METHODS,
    @HTTP_METHODS,
    @ROUTES_METHODS,
);

my $app;

#my %SETTINGS = (_NS => ['']);
my %SETTINGS = ();
my @NS = ('');

sub import {
    my $class = shift;
    $class->export_to_level(1, @_);

    strict->import;
    warnings->import;

    my $caller = caller;
    $app ||= Raisin->new(caller => $caller);
}

#
# Execution
#
sub new { $app->run }
sub run { $app->run }

#
# Compile
#
sub mount { $app->mount_package(@_) }
sub middleware { $app->add_middleware(@_) }

#
# Hooks
#
sub before { $app->add_hook('before', shift) }
sub before_validation { $app->add_hook('before_validation', shift) }

sub after_validation { $app->add_hook('after_validation', shift) }
sub after { $app->add_hook('after', shift) }

#
# Resource DSL
#
sub resource {
    my ($name, $block, %args) = @_;

    if ($name) {
        $name =~ s{^/}{}msx;

        my %prev_settings = %SETTINGS;

        push @NS, $name;
        @SETTINGS{ keys %args } = values %args;

        # Going deeper
        $block->();

        pop @NS;
        %SETTINGS = ();
        %SETTINGS = %prev_settings;
    }

    (join '/', @NS) || '/';
}
sub namespace { resource(@_) }

sub route_param {
    my $code = pop @_;

    my ($param, $spec);
    if (ref $_[0] eq 'HASH') {
        $spec = $_[0];
        $param = $spec->{name};
    }
    else {
        $spec = { name => $_[0], type => $_[1], desc => 'ROUTE PARAM' };
        $param = $_[0];
    }

    resource(":$param", $code, named => [requires => $spec]);
}

#
# Actions
#
sub del     { $app->add_route('DELETE',  resource(), %SETTINGS, @_) }
sub get     { $app->add_route('GET',     resource(), %SETTINGS, @_) }
sub head    { $app->add_route('HEAD',    resource(), %SETTINGS, @_) }
sub options { $app->add_route('OPTIONS', resource(), %SETTINGS, @_) }
sub patch   { $app->add_route('PATCH',   resource(), %SETTINGS, @_) }
sub post    { $app->add_route('POST',    resource(), %SETTINGS, @_) }
sub put     { $app->add_route('PUT',     resource(), %SETTINGS, @_) }

sub desc { _add_route(desc => @_) }
sub params { _add_route(params => @_) }

sub _add_route {
    my @params = @_;
    my $code = pop @params;

    my %pp;
    push(@params, undef) if scalar(@params) % 2;

    for my $p (pairs(@params)) {
        my ($k, $v) = @$p;

        if ($k eq 'desc' || $k eq 'params') {
            $pp{ $k } = $v;
        }
        elsif (grep { $k eq $_ } @HTTP_METHODS) {
            $pp{method} = uc $k =~ /del/i ? 'delete' : $k;
            $pp{path} = $v || '';
        }
    }

    my $method = delete $pp{method};
    my $path = resource();

    $path .= "/$pp{path}" if $pp{path};

#use DDP { class => { expand => 0 } };

    $app->add_route($method, $path, %SETTINGS, %pp, $code);
}


#
# Request and Response shortcuts
#
sub req { $app->req }
sub res { $app->res }
sub param {
    my $name = shift;
    return $app->req->parameters->mixed->{$name} if $name;
    $app->req->parameters->mixed;
}
sub session { $app->session(@_) }

#
# System
#
sub plugin { $app->load_plugin(@_) }

sub api_format { $app->api_format(@_) }
sub api_version { $app->api_version(@_) }

#
# Render
#
sub error { $app->res->render_error(@_) }

1;

__END__

=head1 NAME

Raisin::API - Provides Raisin DSL.

=head1 DESCRIPTION

See L<Raisin>.

=cut
