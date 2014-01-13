package Raisin::Request;

use strict;
use warnings;

use base 'Plack::Request';

sub new {
    my ($class, $app, $env) = @_;
    my $self = $class->SUPER::new($env);
    $self->{app} = $app;
    $self;
}

sub declared_params {
    my ($self, $tokens, $route_params) = @_;
    # + route params
}

sub route_params {

}

1;
