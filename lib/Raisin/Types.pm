package Raisin::Types;

use strict;
use warnings;
no warnings 'redefine';


package Raisin::Types::Integer;
use base 'Raisin::Types::Base';
sub check {
    my ($self, $v) = @_;
    $v =~ /^\d+$/;
}

# ->

package Raisin::Types::Float;
use base 'Raisin::Types::Base';
sub check {
    my ($self, $v) = @_;
    $v =~ /^\d+(?:\.\d+)$/;
}
sub in {
    my ($self, $rv) = @_;
    $$rv = sprintf '%.4f', $$rv;
}

# ->

package Raisin::Types::String;
use base 'Raisin::Types::Base';
sub check {
    my ($self, $v) = @_;
    $v =~ /^[\t\r\n\p{IsPrint}]{0,32766}/;
}

# ->

package Raisin::Types::Scalar;
use base 'Raisin::Types::Base';
sub check {
    my ($self, $v) = @_;
    ref \$v eq 'SCALAR';
}


1;

__END__

=head1 NAME

Raisin::Types - Default parameter types for Raisin.

=head1 DESCRIPTION

Built-in Raisin parameters types.

=over

=item *

C<Raisin::Types::Integer>

=item *

C<Raisin::Types::Float>

=item *

C<Raisin::Types::String>

=item *

C<Raisin::Types::Scalar>

=back

=head1 MAKE YOUR OWN

See L<Raisin::Types::Base>.

=cut
