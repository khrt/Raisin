#!perl
#PODNAME: Raisin::Encoder::Text
#ABSTRACT: Data::Dumper serialization plugin for Raisin.

use strict;
use warnings;

package Raisin::Encoder::Text;

use Data::Dumper;
use Encode 'encode';

sub detectable_by { [qw(text/plain txt)] }
sub content_type { 'text/plain; charset=utf-8' }

sub serialize {
    my ($self, $data) = @_;

    $data = Data::Dumper->new([$data], ['data'])
        ->Sortkeys(1)
        ->Purity(1)
        ->Terse(1)
        ->Deepcopy(1)
        ->Dump;
    $data = encode('UTF-8', $data);
    $data;
}

sub deserialize {
    Raisin::log(error => 'Raisin:Encoder::Text doesn\'t support deserialization');
    die;
}

1;

__END__

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=cut
