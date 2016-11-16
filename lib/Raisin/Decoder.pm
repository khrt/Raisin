package Raisin::Decoder;

use strict;
use warnings;

use parent 'Raisin::Encoder';

sub builtin {
    {
        json => 'Raisin::Encoder::JSON',
        yaml => 'Raisin::Encoder::YAML',
    };
}

1;

__END__

=head1 NAME

Raisin::Decoder - A helper for L<Raisin::Middleware::Formatter> over decoder modules.

=head1 SYNOPSIS

    my $dec = Raisin::Decoder->new;
    $dec->register(xml => 'Some::XML::Parser');
    $dec->for('json');
    $dec->media_types_map_flat_hash;

=head1 DESCRIPTION

Provides an easy interface to use and register decoders.

The interface is identical to L<Raisin::Encoder>.

=head1 METHODS

=head2 builtin

Returns a list of encoders which are bundled with L<Raisin>.
They are: L<Raisin::Encoder::JSON>, L<Raisin::Encoder::YAML>.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
