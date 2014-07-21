package Raisin::API;

use strict;
use warnings;

use parent 'Exporter';

use Carp;
use Raisin;

my @APP_CONF_METHODS = qw(api_default_format api_format api_version middleware mount plugin);
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
# Resource
#
sub resource {
    my ($name, $code, %args) = @_;

    if ($name) {
        $name =~ s{^/}{}msx;

        my %prev_settings = %SETTINGS;

        push @NS, $name;
        @SETTINGS{ keys %args } = values %args;

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
    my $code = pop @_;

    my ($param, $spec);
    if (ref $_[0] eq 'HASH') {
        $spec = $_[0];
        $param = $spec->{name};
    }
    else {
        $spec = { name => $_[0], type => $_[1], desc => $_[0] };
        $param = $_[0];
    }

    resource(":$param", $code, named => [requires => $spec]);
}

#
# Actions
#
sub del     { _add_route('del', @_) }
sub get     { _add_route('get', @_) }
sub head    { _add_route('head', @_) }
sub options { _add_route('options', @_) }
sub patch   { _add_route('patch', @_) }
sub post    { _add_route('post', @_) }
sub put     { _add_route('put', @_) }

sub desc    { _add_route('desc', @_) }
sub params  { _add_route('params', @_) }

sub _add_route {
    my @params = @_;

    my %pp = (%SETTINGS, code => pop @params);

    my $i = 0;
    while ($i < scalar(@params)) {
        my $k = $params[$i];
        my $v = $params[$i + 1] || undef;

        if ($k eq 'desc' || $k eq 'params') {
            $pp{ $k } = $v;
#            splice @params, $i, 2, '', '';
        }
        elsif (grep { $k =~ /^$_$/imsx } @HTTP_METHODS) {
            $pp{method} = $k =~ /del/i ? 'delete' : $k;
            $pp{path} = resource() . ($v ? "/$v" : '');
        }
        elsif ($k =~ /^resource|namespace$/msx) {
            $pp{resource} = $v;
        }
        elsif ($k eq 'route_param') {
            $pp{$k} = $v;
        }

        $i++;
    }

    if ($pp{resource}) {
        my $path = resource($pp{resource}, $pp{code});
        #$path .= $pp{resource};
        $app->add_resource_desc(%pp);
    }
    elsif ($pp{route_param}) {
        my $path = resource(":$pp{route_param}", $pp{code}, named => $pp{params});
        #$path .= "/:$pp{route_param}";
        #$app->add_resource_desc(resource => $path, desc => $pp{desc});
    }
    else {
        $app->add_route(%pp);
    }
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

sub api_default_format { $app->api_default_format(@_) }
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
