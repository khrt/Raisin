package Raisin::API;

use strict;
use warnings;

use base 'Exporter';

use Raisin;

our @EXPORT = qw(
    run new

    mount middleware

    plugin api_format api_version

    before before_validation
    after_validation after

    namespace route_param params
    req res param session
    del get head options patch post put
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
sub run { $app->run }
sub new { $app->run }

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
# Namespace DSL
#
sub namespace {
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

sub route_param {
    my ($param, $type, $block) = @_;
    namespace(":$param", $block, named => [required => [$param, $type]]);
}

#
# Actions
#
sub del     { $app->add_route('DELETE',  namespace(), %SETTINGS, @_) }
sub get     { $app->add_route('GET',     namespace(), %SETTINGS, @_) }
sub head    { $app->add_route('HEAD',    namespace(), %SETTINGS, @_) }
sub options { $app->add_route('OPTIONS', namespace(), %SETTINGS, @_) }
sub patch   { $app->add_route('PATCH',   namespace(), %SETTINGS, @_) }
sub post    { $app->add_route('POST',    namespace(), %SETTINGS, @_) }
sub put     { $app->add_route('PUT',     namespace(), %SETTINGS, @_) }

sub params {
    my ($params, $method, @other) = @_;
    my $code = pop @other;

    my @args;
    if (scalar @other == 1) {
        push @args, shift @other;
    }
    push @args, $code;

    $app->add_route(uc($method), namespace(), %SETTINGS, params => $params, @args);
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
