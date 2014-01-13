package Raisin::Response;

use strict;
use warnings;

use base 'Plack::Response';

sub new {
    my ($class, $app) = @_;
    my $self = $class->SUPER::new();
    $self->{app} = $app;
    $self;
}

sub app { $_[0]->{app} }


sub json {
    my ($self, $enable) = @_;
    $self->{json} = $enable ? 0 : 1;
    $self->{json};
}

sub rendered {

}

sub render {

}

sub render_error {

}

1;
