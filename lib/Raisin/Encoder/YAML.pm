package Raisin::Encoder::YAML;

use strict;
use warnings;

use Encode qw(encode_utf8 decode_utf8);
use YAML qw(Dump Load);

sub detectable_by { [qw(application/x-yaml application/yaml text/x-yaml text/yaml yaml)] }
sub content_type { 'application/x-yaml' }
sub serialize { encode_utf8( Dump($_[1]) ) }
sub deserialize { Load( decode_utf8($_[1]) ) }

1;

__END__

=head1 NAME

Raisin::Encoder::YAML - YAML serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
