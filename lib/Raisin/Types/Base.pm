package Raisin::Types::Base;

use strict;
use warnings;
no warnings 'redefine';

use Raisin::Attributes;

has name => sub {
    my $class = shift;
    my $name = (split /::/, $class)[-1];
    $name;
};

has check => sub { 1 };
has in => sub { 1 };
has regex => undef;

sub new {
    my ($class, $ref_value) = @_;
    my $self = bless {}, $class;

    if ($self->regex) {
        return unless $$ref_value =~ $self->regex;
    }

    $self->check($$ref_value) or return;
    $self->in($ref_value);
    $self;
}

1;

__END__

=head1 NAME

Raisin::Types::Base - Base class for Raisin::Types.

=head1 SYNOPSIS

    package Raisin::Types::Integer;
    use base 'Raisin::Types::Base';

    sub regex { qr/^\d+$/ }
    sub check {
        my ($self, $v) = @_;
        length($v) <= 10 ? 1 : 0
    }
    sub in {
        my ($self, $v) = @_; # REF
        $$v = sprintf 'INT:%d', $$v;
    }

    package main;

    # validate 10.1
    use Raisin::Types::Integer;

    warn Raisin::Types::Integer->new(1234) ? 'valid' : 'invalid';
    warn Raisin::Types::Integer->new(10.1) ? 'valid' : 'invalid';

=head1 DESCRIPTION

Base class for each Raisin type.

Contains two base methods: C<check> and C<in>.

=head1 METHODS

=head3 regex

Type regex.

=head3 check

Check value.

=head3 in

Apply some actions on the value.

=cut
