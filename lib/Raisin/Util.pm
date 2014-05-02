package Raisin::Util;

use strict;
use warnings;

my %SERIALIZERS = (
    json     => 'Raisin::Plugin::Format::JSON',
    json_rpc => 'Raisin::Plugin::Format::JSON',
    yaml     => 'Raisin::Plugin::Format::YAML',
    yml      => 'Raisin::Plugin::Format::YAML',
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

Detect serializer by content type.

=cut
