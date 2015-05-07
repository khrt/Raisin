package Raisin::Request;

use strict;
use warnings;

use parent 'Plack::Request';

use Raisin::Util;

sub new {
    my ($class, $app, $env) = @_;
    my $self = $class->SUPER::new($env);
    $self->{app} = $app;
    $self;
}

sub app { shift->{app} }

sub accept_format {
    my $self = shift;

    my $accept = $self->header('Accept');
    return unless $accept;
    return if $accept eq '*/*';
    Raisin::Util::detect_serializer($accept) || $accept;
}

sub deserialize {
    my ($self, $data) = @_;

    my $serializer = do {
        if (my $f = Raisin::Util::detect_serializer($self->content_type)) {
            Plack::Util::load_class(Raisin::Util::make_serializer_class($f));
        }
        elsif ($self->app->can('serializer')) {
            $self->app->serializer;
        }
    };

    if ($serializer) {
        $data = $serializer->deserialize($data);
    }

    $data;
}

sub prepare_params {
    my ($self, $declared, $named) = @_;

    $self->{'raisin.declared'} = $declared;

    # Serialization / Deserialization
    my $body_params = do {
        if ($self->method =~ /POST|PUT/ && (my $content = $self->content)) {
            if ($self->content_type =~ m{application/x-www-form-urlencoded}imsx) {
                $self->body_parameters->as_hashref_mixed;
            }
            else {
                $self->deserialize($content);
            }
        }
    };

    my $query_params = $self->query_parameters->as_hashref_mixed;
    my $params = { %{ $body_params || {} }, %{ $query_params || {} } };

    $self->{'raisin.parameters'} = { %$params, %{ $named || {} } };

    foreach my $p (@$declared) {
        my $name = $p->name;

        # a route params have a precedence over query params
        my $value = $named->{$name} // $params->{$name};

        if (not $p->validate(\$value)) {
            $p->required ? return : next;
        }

        $value //= $p->default if defined $p->default;
        next if not defined($value);

        $self->{'raisin.declared_params'}{$name} = $value;
    }

    1;
}

sub declared_params { shift->{'raisin.declared_params'} }

sub parameters {
    my $self = shift;
    $self->{'raisin.parameters'};
}

1;

__END__

=head1 NAME

Raisin::Request - Request class for Raisin.

=head1 SYNOPSIS

    Raisin::Request->new($self, $env);

=head1 DESCRIPTION

Extends L<Plack::Request>.

=head1 METHODS

=head3 accept_format

=head3 deserialize

=head3 declared_params

=head3 prepare_params

=head3 parameters

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
