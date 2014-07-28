package Raisin::Plugin::Format::JSON;

use strict;
use warnings;

use parent 'Raisin::Plugin';

use JSON qw(to_json from_json);

sub build {
    my ($self, %args) = @_;

    $self->register(
        serializer => $self,
    );
}

sub content_type { 'application/json' }

sub deserialize { from_json $_[1] }
sub serialize   { to_json $_[1], { utf8 => 0 } }

1;

__END__

=head1 NAME

Raisin::Plugin::Format::JSON - JSON serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<deserialize> and C<serialize> methods for Raisin.

=cut
