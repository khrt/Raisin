package Raisin::Request;

use strict;
use warnings;

use base 'Plack::Request';

sub new {
    my ($class, $env) = @_;
    my $self = $class->SUPER::new($env);
    $self;
}

sub declared_params {
    my ($self, $tokens, $route_params) = @_;
    # + route params
}

sub merge_route_params {
    my ($self, $route_params) = @_;

}

1;
