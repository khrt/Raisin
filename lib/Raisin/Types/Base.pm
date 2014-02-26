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

Raisin::Types::Base - Base class for Raisin::Types.

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

Base class for each Raisin type.

Contains two method base methods: C<check> and C<in>.

=head1 METHODS

=head3 check

Check value.

    $Price->check(\$value);

=head3 in

Apply some actions on the value.

    $Price->in(\$value);

=cut
