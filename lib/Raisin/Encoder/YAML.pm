#!perl
#PODNAME: Raisin::Encoder::YAML
#ABSTRACT: YAML serialization plugin for Raisin.

use strict;
use warnings;

package Raisin::Encoder::YAML;

use Encode qw(encode_utf8 decode_utf8);
use YAML qw(Dump Load);

sub detectable_by { [qw(application/x-yaml application/yaml text/x-yaml text/yaml yaml)] }
sub content_type { 'application/x-yaml' }
sub serialize { encode_utf8( Dump($_[1]) ) }
sub deserialize { Load( decode_utf8($_[1]) ) }

1;

__END__

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=cut
