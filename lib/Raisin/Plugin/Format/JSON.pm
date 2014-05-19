package Raisin::Plugin::Format::JSON;

use strict;
use warnings;

use base 'Raisin::Plugin';

use JSON qw(encode_json decode_json);

sub build {
    my ($self, %args) = @_;

    $self->register(
        serializer => $self,
    );
}

sub content_type { 'application/json' }

sub deserialize { decode_json $_[1] }
sub serialize   { encode_json $_[1] }

1;

__END__

=head1 NAME

Raisin::Plugin::Format::JSON - JSON serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<deserialize> and C<serialize> methods for Raisin.

=cut
