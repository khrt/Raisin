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

sub app { shift->{app} }

sub declared_params { shift->{'raisin.params'} }

sub set_declared_params {
    my ($self, $declared) = @_;
    $self->{'raisin.params.declared'} = $declared;
}

sub set_named_params {
    my ($self, $named) = @_;
    $self->{'raisin.params.named'} = $named;
}

sub populate_params {
    my $self = shift;

    my $declared = $self->{'raisin.params.declared'};
    my $named = $self->{'raisin.params.named'};

    # Serialization / Deserialization
    my $params = do {
        if ($self->method =~ /POST|PUT/ && (my $content = $self->content)) {
            if ($self->app->can('deserialize')
                && ($self->content_type eq $self->app->default_content_type))
            {
                $self->app->deserialize($content);
            }
            elsif ($self->content_type eq 'application/x-www-form-urlencoded') {
                $self->body_parameters->mixed;
            }
        }
        else {
            $self->query_parameters->mixed;
        }
    };

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
