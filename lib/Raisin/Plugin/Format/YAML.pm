package Raisin::Plugin::Format::YAML;

use strict;
use warnings;

use parent 'Raisin::Plugin';

use YAML qw(Dump Load);

sub build {
    my ($self, %args) = @_;

    $self->register(
        serializer => $self,
    );
}

sub content_type { 'application/yaml' }

sub deserialize { Load $_[1] }
sub serialize { Dump $_[1] }

1;

__END__

=head1 NAME

Raisin::Plugin::Format::YAML - YAML serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<deserialize> and C<serialize> methods for Raisin.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
