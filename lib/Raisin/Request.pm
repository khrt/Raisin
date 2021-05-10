#!perl
#PODNAME: Raisin::Request
#ABSTRACT: Request class for Raisin.

use strict;
use warnings;

package Raisin::Request;

use parent 'Plack::Request';

sub build_params {
    my ($self, $endpoint) = @_;

    my %params = (
        %{ $self->env->{'raisinx.body_params'} || {} },         # 3. Body
        %{ $self->query_parameters->as_hashref_mixed || {} },   # 2. Query
        %{ $endpoint->named || {} },                            # 1. Path
    );

    $self->{'raisin.parameters'} = \%params;
    $self->{'raisin.declared'} = $endpoint->params;

    my $success = 1;

    foreach my $p (@{ $endpoint->params }) {
        my $name = $p->name;
        my $value = $params{$name};

        if (not $p->validate(\$value)) {
            $success = 0;
            $p->required ? return : next;
        }

        $value //= $p->default if defined $p->default;
        next if not defined($value);

        $self->{'raisin.declared_params'}{$name} = $value;
    }

    $success;
}

sub declared_params { shift->{'raisin.declared_params'} }
sub raisin_parameters { shift->{'raisin.parameters'} }

1;

__END__

=head1 SYNOPSIS

    Raisin::Request->new($self, $env);

=head1 DESCRIPTION

Extends L<Plack::Request>.

=head1 METHODS

=head3 declared_params

=head3 build_params

=head3 raisin_parameters

=cut
