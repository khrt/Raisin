package Raisin::Encoder::Text;

use strict;
use warnings;

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

=head1 NAME

Raisin::Encoder::Text - Data::Dumper serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
