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
    Data::Dumper->new([$_[1]], ['data'])->Purity(1)->Terse(1)->Deepcopy(1)->Dump;
}

1;

__END__

=head1 NAME

Raisin::Plugin::Format::Text - Data::Dumper serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<deserialize> and C<serialize> methods for Raisin.

=cut
