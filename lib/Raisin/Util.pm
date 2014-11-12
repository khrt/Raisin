package Raisin::Util;

use strict;
use warnings;

use Plack::Util;

my %SERIALIZERS = (
    json     => 'json',
    json_rpc => 'json',
    yaml     => 'yaml',
    yml      => 'yaml',
    text     => 'text',
    txt      => 'text',
);

sub detect_serializer {
    my $type = shift;
    return unless $type;

    $type =~ s{^(.+)/}{};
    $type =~ tr{-}{_};

    $SERIALIZERS{$type};
}

sub make_serializer_class {
    my $format = shift;
    'Raisin::Plugin::Format::' . uc($format);
}

1;

__END__

=head1 NAME

Raisin::Util - Utility subroutine for Raisin.

=head1 FUNCTIONS

=head2 detect_serializer

Detects serializer by content type or extension.

=head2 make_serializer_class

Returns C<Raisin::Plugin::Format::E<lt>NAMEE<gt>> class name.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
