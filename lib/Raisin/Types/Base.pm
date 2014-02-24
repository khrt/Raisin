package Raisin::Types::Base;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    @$self{qw(check in)} = @args{qw(check in)};
    $self;
}

sub check {
    my ($self, $v) = @_;
    $self->{check}->($v);
}

sub in { shift->{in} }

1;

__END__

=head1 NAME

Raisin::Types::Base

=head1 SYNOPSIS

    my $Price =
        Raisin::Types::Base->new(
            check => sub {
                my $v = shift;
                return if ref $v;
                $v =~ /^[\d.]*$/;
            },
            in => sub {
                my $v = shift; # SCALAR REF
                $$v = sprintf '%.2f', $$v;
            },
        );

=head1 DESCRIPTION

C<check> then C<in>.

=head3 new

Create new type.

=head3 check

Check subroutine.

=head3 in

Some actions on the value.

=cut
