package Raisin::Request;

use strict;
use warnings;

use Carp;
use base 'Plack::Request';

sub new {
    my ($class, $env) = @_;
    my $self = $class->SUPER::new($env);
    $self;
}

sub set_declared_params {
    my ($self, $declared) = @_;
    $self->{'app.params.declared'} = $declared if $declared;
}

sub set_named_params {
    my ($self, $named) = @_;
    $self->{'app.params.named'} = $named if $named;
}

sub validate_params {
    my $self = shift;

    my $declared = $self->{'app.params.declared'};
    my $named = $self->{'app.params.named'};
    my $params = $self->parameters->mixed;

    my %declared_params;
    foreach my $p (@$declared) {
        my $name = $p->name;

        # NOTE Route params has more precedence than query params
        my $value = $named->{$name} || $params->{$name} || $p->default;

        # What TODO if parameters is invalid?
        if (not $p->validate($value)) {
            carp "$name is invalid!";
            return;
        }

        next if not defined($value);
        $self->{'app.params'}{$name} = $value;
    }

    1;
}

sub declared_params { shift->{'app.params'} }

1;
