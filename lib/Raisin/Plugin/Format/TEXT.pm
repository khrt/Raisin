package Raisin::Plugin::Format::TEXT;

use strict;
use warnings;

use parent 'Raisin::Plugin';

use Data::Dumper;

sub build {
    my ($self, %args) = @_;

    $self->register(
        serializer => $self,
    );
}

sub content_type { 'text/plain' }

sub deserialize { $_[1] }
sub serialize {
    Data::Dumper->new([$_[1]], ['data'])
        ->Sortkeys(1)
        ->Purity(1)
        ->Terse(1)
        ->Deepcopy(1)
        ->Dump;
}

1;

__END__

=head1 NAME

Raisin::Plugin::Format::TEXT - Data::Dumper serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<deserialize> and C<serialize> methods for Raisin.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
