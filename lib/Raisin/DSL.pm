package Raisin::DSL;

use strict;
use warnings;
use feature ':5.12';

use base 'Exporter';

use Raisin;
use DDP; # XXX

our @EXPORT = qw(
    to_app run
    mount new

    hook
    namespace route_param
    req res params session
    delete get head options patch post put
    plugin api_format
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
    feature->import(':5.12');

    my $caller = caller;
    $app ||= Raisin->new(caller => $caller);
}

#
# Execution
#
sub run { $app->run(@_) }
sub to_app { sub { $app->psgi(@_) } }
#sub to_app { $app->run(@_) }

#
# Compile
#
sub mount { $app->mount_package(@_) }

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
# Action DSL
#
sub delete  { $app->add_route('DELETE',  namespace(), %SETTINGS, @_) }
sub get     { $app->add_route('GET',     namespace(), %SETTINGS, @_) }
#sub head    { $app->add_route('HEAD',    namespace(), %SETTINGS, @_) }
#sub options { $app->add_route('OPTIONS', namespace(), %SETTINGS, @_) }
#sub patch   { $app->add_route('PATCH',   namespace(), %SETTINGS, @_) }
sub post    { $app->add_route('POST',    namespace(), %SETTINGS, @_) }
sub put     { $app->add_route('PUT',     namespace(), %SETTINGS, @_) }

#
# Request and Response shortcuts
#
sub req { $app->req }
sub res { $app->res }
sub params { $app->params(@_) }
sub session { $app->session(@_) }

#
#
#
sub plugin { $app->load_plugin(@_) }
sub api_format { $app->api_format(@_) }

#sub error {
#    # NOTE render error 500?
#    $app->res->render_error(@_);
#}

1;
