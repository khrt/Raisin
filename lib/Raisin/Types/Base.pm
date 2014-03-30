package Raisin::Types::Base;

use strict;
use warnings;
no warnings 'redefine';

sub name { (split /::/, (shift || __PACKAGE__))[-1] }

sub constraint { 1 }
sub coercion { 1 }

sub new {
    my ($class, $ref_value) = @_;
    my $self = bless {}, $class;

    $self->constraint($$ref_value) or return;
    $self->coercion($ref_value);
    $self;
}

1;

__END__

=head1 NAME

Raisin::Types::Base - Base class for Raisin::Types.

=head1 SYNOPSIS

    package Raisin::Types::Integer;
    use base 'Raisin::Types::Base';

    sub constraint {
        my ($self, $v) = @_;
        length($v) <= 10 ? 1 : 0
    }
    sub coercion {
        my ($self, $v) = @_; # REF
        $$v = sprintf 'INT:%d', $$v;
    }

    package main;

    use Raisin::Types::Integer;

    say Raisin::Types::Integer->new(1234) ? 'valid' : 'invalid';
    say Raisin::Types::Integer->new(10.1) ? 'valid' : 'invalid';

=head1 DESCRIPTION

Base class for each Raisin type.

Contains three base methods: C<name>, C<constraint> and C<coercion>.

=head1 METHODS

=head3 name

Return type's name.

By default will be returned last string after after C<::>.
If you want customize variable name you can redefine C<name> subroutine.

    sub name { 'FancyTypeName' }

=head3 constraint

    sub constraint {
        my ($self, $v) = @_;
        length($v) <= 10 ? 1 : 0
    }

=head3 coercion

    sub coercion {
        my ($self, $v) = @_; # REF
        $$v = sprintf 'INT:%d', $$v;
    }

=cut
