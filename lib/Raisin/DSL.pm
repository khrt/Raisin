package Raisin::DSL;

use strict;
use warnings;
use feature ':5.12';

use base 'Exporter';

use Raisin;

our @EXPORT = qw(
    to_app run
    hook
    namespace route_param
    req res params session
    delete get head options patch post put
);

my $app;
my %SETTINGS = (_NS => ['']);

sub import {
    my $class = shift;
    my $caller = caller;

    $class->export_to_level(1, @_);

    strict->import;
    warnings->import;
    feature->import(':5.12');

    $app = Raisin->new;
}

#
# Execution
#
sub to_app { $app->psgi }
sub run    { $app->run(@_) }

#
# Hook
#
sub hook {
    my ($hook, $block) = @_;

    # Available hooks:
    #   * before
    #   * before_validation
    #   * after_validation
    #   * after

}

#
# Helpers
#
sub helpers {

}

#
# Namespace DSL
#
sub namespace {
    my ($name, $block, %args) = @_;

    if ($name) {
        my %prev_settings = %SETTINGS;

        push(@{ $SETTINGS{_NS} }, $name);
        @SETTINGS{ keys %args } = values %args;

        # Going deeper
        $block->();

        %SETTINGS = %prev_settings;
    }

    (join '/', @{ $SETTINGS{_NS} }) || '/'
}


sub route_param {
    my ($param, $type, $block) = @_; # TODO Types: + DEFAUT, REGEX
    namespace(":$param", $block, route_params => [required => [$param, $type]]);
}

#
# Action DSL
#
sub delete  { $app->add_route('DELETE',  namespace(), %SETTINGS, @_) }
sub get     { $app->add_route('GET',     namespace(), %SETTINGS, @_) }
sub head    { $app->add_route('HEAD',    namespace(), %SETTINGS, @_) }
sub options { $app->add_route('OPTIONS', namespace(), %SETTINGS, @_) }
sub patch   { $app->add_route('PATCH',   namespace(), %SETTINGS, @_) }
sub post    { $app->add_route('POST',    namespace(), %SETTINGS, @_) }
sub put     { $app->add_route('PUT',     namespace(), %SETTINGS, @_) }

#
# Request and Response shortcuts
#
sub req { $app->req };
sub res { $app->res };
sub params { $app->params(@_) };
sub session { $app->session(@_) };

1;
