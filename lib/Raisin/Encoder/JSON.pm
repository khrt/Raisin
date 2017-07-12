package Raisin::Encoder::JSON;

use strict;
use warnings;

use JSON qw(encode_json decode_json);

our $json = JSON->new()->utf8();

sub detectable_by { [qw(application/json text/x-json text/json json)] }
sub content_type { 'application/json' }
sub serialize { $json->encode($_[1]) }
sub deserialize { $json->decode($_[1]) }

1;

__END__

=head1 NAME

Raisin::Encoder::JSON - JSON serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=head1 ADJUST ENCODER

The $Raisin::Encoder::JSON::json variable is the object used for encoding and decoding.

Therefore you can tweak the encoding (and decoding like so)

 $Raisin::Encoder::JSON::json->pretty(1);
 $Raisin::Encoder::JSON::json->indent(1);
 etc...

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
