#!perl
#PODNAME: Raisin::Encoder::Form
#ABSTRACT: Form deserialization plugin for Raisin.

use strict;
use warnings;

package Raisin::Encoder::Form;

use Encode qw(decode_utf8);

sub detectable_by { [qw(application/x-www-form-urlencoded multipart/form-data)] }
sub content_type { 'text/plain; charset=utf-8' }

sub serialize {
    Raisin::log(error => 'Raisin:Encoder::Form doesn\'t support serialization');
    die;
}

sub deserialize { $_[1]->body_parameters }

1;

__END__

=head1 DESCRIPTION

Provides C<deserialize> method to decode HTML form data requests.

=cut
