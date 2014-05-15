package Raisin::Util;

use strict;
use warnings;

my %SERIALIZERS = (
    json     => 'json',
    json_rpc => 'json',
    yaml     => 'yaml',
    yml      => 'yaml',
);

sub detect_serializer {
    my $type = shift;
    return unless $type;

    $type =~ s{^(.+)/}{};
    $type =~ tr{-}{_};

    $SERIALIZERS{$type};
}

1;

__END__

=head1 NAME

Raisin::Utils - Utility subroutine for Raisin.

=head1 FUNCTIONS

=head2 detect_serializer

Detect serializer by content type or extension.

=cut
