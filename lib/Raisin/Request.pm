package Raisin::Request;

use strict;
use warnings;

use parent 'Plack::Request';

sub prepare_params {
    my ($self, $declared, $named) = @_;

    $self->{'raisin.declared'} = $declared;

    # PRECEDENCE:
    #   - path
    #   - query
    #   - body
    my %params = (
        %{ $self->env->{'raisinx.body_params'} || {} },
        %{ $self->query_parameters->as_hashref_mixed || {} },
        %{ $named || {} },
    );

    $self->{'raisin.parameters'} = \%params;

    my $retval = 1;

    foreach my $p (@$declared) {
        my $name = $p->name;
        my $value = $params{$name};

        if (not $p->validate(\$value)) {
            $retval = 0;
            $p->required ? return : next;
        }

        $value //= $p->default if defined $p->default;
        next if not defined($value);

        $self->{'raisin.declared_params'}{$name} = $value;
    }

    $retval;
}

sub declared_params { shift->{'raisin.declared_params'} }
sub raisin_parameters { shift->{'raisin.parameters'} }

1;

__END__

=head1 NAME

Raisin::Request - Request class for Raisin.

=head1 SYNOPSIS

    Raisin::Request->new($self, $env);

=head1 DESCRIPTION

Extends L<Plack::Request>.

=head1 METHODS

=head3 declared_params

=head3 prepare_params

=head3 raisin_parameters

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
