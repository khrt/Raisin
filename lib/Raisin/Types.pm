package Raisin::Types;

use strict;
use warnings;

use Raisin::Types::Base;

our $Scalar
    = Raisin::Types::Base->new(
        check => sub {
            my $v = shift;
            ref \$v eq 'SCALAR';
        },
        #in => sub {},
    );

our $String
    = Raisin::Types::Base->new(
        check => sub {
            my $v = shift;
            $v =~ /^[\t\r\n\p{IsPrint}]{0,32766}/;
        },
        #in => sub {},
    );

our $Integer
    = Raisin::Types::Base->new(
        check => sub {
            my $v = shift;
            $v =~ /^\d+$/;
        },
        #in => sub {},
    );

1;

__END__

=head1 NAME

Raisin::Types - default types for Raisin

=head1 DESCRIPTION

Built-in types for Raisin.

=over

=item *

C<Raisin::Types::Integer>

=item *

C<Raisin::Types::String>

=item *

C<Raisin::Types::Scalar>

=back

=head1 MAKE YOUR OWN

See L<Raisin::Types::Base>.

=cut
