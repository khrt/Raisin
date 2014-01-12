package Raisin::DSL; # TODO -> Raisin::API

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
my @NS = ('');

sub import {
    my $class = shift;
    my $caller = caller;

    $class->export_to_level(1, @_);

    strict->import;
    warnings->import;
    feature->import(':5.12');

    $app = Raisin->new;
#    $app->routes->base('main');
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
    my ($name, $block) = @_;

    if ($name) {
        my @prev_ns = @NS;
        push(@NS, $name);

        eval { $block->() };
        die $@ if $@;

        @NS = @prev_ns;
    }

    (join '/', @NS) || '/'
}


sub route_param {
    my ($param, $type, $block) = @_;
    namespace("<$param>", $block);
}

#
# Action DSL
#
sub delete  { $app->add_route('DELETE',  namespace, @_) }
sub get     { $app->add_route('GET',     namespace, @_) }
sub head    { $app->add_route('HEAD',    namespace, @_) }
sub options { $app->add_route('OPTIONS', namespace, @_) }
sub patch   { $app->add_route('PATCH',   namespace, @_) }
sub post    { $app->add_route('POST',    namespace, @_) }
sub put     { $app->add_route('PUT',     namespace, @_) }

#
# Request and Response shortcuts
#
sub req { $app->req };
sub res { $app->res };
sub params { $app->params(@_) };
sub session { $app->session(@_) };

1;
