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
#my %SETTINGS = (_NS => ['']);
my %SETTINGS = ();
my @NS = ('');

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
        my @prev_ns = @NS;

        push(@{ $SETTINGS{_NS} }, $name);
        push @NS, $name;
        @SETTINGS{ keys %args } = values %args;

        # Going deeper
        $block->();

        @NS = @prev_ns;
        %SETTINGS = ();
        %SETTINGS = %prev_settings;
    }

    #(join '/', @{ $SETTINGS{_NS} }) || '/'
    (join '/', @NS) || '/'
}


sub route_param {
    my ($param, $type, $block) = @_;
    # TODO Types: regex
    # TODO Types: default value
    # GOOD
    #namespace(":$param", $block, route_params => [required => [$param, $type]]);

    # BAD
    my $type_re = $type->regex;
    $type_re =~ s/\(\?\^:\^(.+?)\$\)/$1/g;
    namespace(
        qr#(?<$param>$type_re)#,
        $block,
        route_params => [required => [$param, $type]]
    );
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
