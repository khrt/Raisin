package Raisin::Types;

use strict;
use warnings;

use Regexp::Common;
use Raisin::Types::Base;

our $Scalar
    = Raisin::Types::Base->new(
        #default => '',
        check => sub {
            my ($self, $v) = @_;
            ref \$v eq 'SCALAR';
        },
        #in => sub {},
        #regex => qr//,
    );

our $String
    = Raisin::Types::Base->new(
        default => '',
        check => sub {
            my ($self, $v) = @_;
            $v =~ /${ $self->regex }/;
        },
        #in => sub {},
        regex => qr/^[\t\r\n\p{IsPrint}]{0,32766}$/,
    );

our $Integer
    = Raisin::Types::Base->new(
        default => 0,
        check => sub {
            my ($self, $v) = @_;
            $v =~ /${ $self->regex }/;
        },
        #in => sub {},
        regex => qr/^\d+$/,
    );

1;

__END__

=pod

=head1 NAME

Raisin::Types - default types for Raisin

=head1 SYNOPSYS

=head1 DESCRIPTION

=over

=cut
