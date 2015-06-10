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

    plain    => 'text',
);

sub valid_extensions {
    keys %SERIALIZERS;
}

sub detect_serializer {
    my $type = shift;
    return unless $type;

    my $media = 'default';

    if ($type =~ m#^([^/]+)/\*#) {
        $media = $1;
    }
    else {
        $type =~ m#(?:^[^/]+/)?(.+)#msix;
        $media = $1;
        $media =~ tr#-#_#;
    }

    $SERIALIZERS{$media};
}

sub make_serializer_class {
    my $format = shift;
    'Raisin::Plugin::Format::' . uc($format);
}

sub make_tag_from_path {
    my $path = shift;
    (split '/', $path)[1];
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

=head2 make_tag_from_path

Splits a path and returns the first part of it.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
