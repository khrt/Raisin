package Raisin::Types;

use strict;
use warnings;

use Type::Tiny;
use Types::Standard;

our $Any = Types::Standard::Any->create_child_type;
our $Bool = Types::Standard::Bool->create_child_type;
our $Defined = Types::Standard::Defined->create_child_type;
our $Integer = Types::Standard::Int->create_child_type;
our $Numeric = Types::Standard::Num->create_child_type;
our $String = Types::Standard::Str->create_child_type;
our $Undef = Types::Standard::Undef->create_child_type;
our $Value = Types::Standard::Value->create_child_type;

#use DDP;
#my $num = Type::Tiny->new(
#   constraint => sub { looks_like_number($_) },
#   message    => sub { "$_ ain't a number" },
#   name       => "Number",
#);
#p $num;
#p $num->(1);
#p $num->(1.23);
#p $num->('string');

1;

__END__

=head1 NAME

Raisin::Types - Default parameter types for Raisin.

=head1 DESCRIPTION

Built-in Raisin parameters types. See L<Types::Standard>.

=over

=item *

C<Any>

=item *

C<Bool>

=item *

C<Defined>

=item *

C<Integer>

=item *

C<Numeric>

=item *

C<String>

=item *

C<Undef>

=item *

C<Value>

=back

=head1 MAKE YOUR OWN

See L<Type::Tiny::Manual>.

=cut
