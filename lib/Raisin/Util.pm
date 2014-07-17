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

Raisin::Utils - Utility subroutine for Raisin.

=head1 FUNCTIONS

=head2 detect_serializer

Detects serializer by content type or extension.

=head2 make_serializer_class

Returns C<Raisin::Plugin::Format::E<lt>NAMEE<gt>> class name.

=cut
