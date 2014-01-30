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

sub declared_params { shift->{'raisin.params'} }

sub set_declared_params {
    my ($self, $declared) = @_;
    $self->{'raisin.params.declared'} = $declared if $declared;
}

sub set_named_params {
    my ($self, $named) = @_;
    $self->{'raisin.params.named'} = $named if $named;
}

sub validate_params {
    my $self = shift;

    my $declared = $self->{'raisin.params.declared'};
    my $named = $self->{'raisin.params.named'};
    my $params = $self->parameters->mixed;

    foreach my $p (@$declared) {
        my $name = $p->name;

        # Route params has more precedence than query params
        my $value = $named->{$name} // $params->{$name};

        if (not $p->validate(\$value)) {
            $p->required ? return : next;
        }

        $value //= $p->default if defined $p->default;
        next if not defined($value);

        $self->{'raisin.params'}{$name} = $value;
    }

    1;
}

1;
