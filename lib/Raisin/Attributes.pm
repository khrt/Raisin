package Raisin::Attributes;

use strict;
use warnings;
no warnings 'redefine';

sub import {
    my $caller = caller;
    if (not $caller->can('has')) {
        no strict 'refs';
        *{"${caller}::has"} = sub { _attr($caller, @_) };
    }
}

sub _attr {
    my ($class, $name, $default) = @_;

    my $attr;
    if (ref $default eq 'CODE') {
        $attr = $default;
    }
    else {
        $attr = sub {
            my ($self, $value) = @_;
            $self->{$name} = $value if defined $value;
            $self->{$name} // $default;
        };
    }

    no strict 'refs';
    *{"${class}::$name"} = $attr;
}

1;

__END__

=head1 NAME

Raisin::Attributes - Simple attributes accessors for Raisin.

=head1 SYNOPSIS

    use Raisin::Attributes;

    has hello => sub { 'hello' };
    say $self->hello; # -> hello

    has 'new';
    say $self->new; # -> undef

    has key => 'value';
    say $self->key; # -> value

=head1 DESCRIPTION

Simple implementation of attribute accessors.

=head1 METHODS

=head3 has

This code:

    has key => 'value';

Will produce:

    sub key {
        my ($self, $value) = @_;
        $self->{key} = $value if defined $value;
        return $self->{key} // 'value';
    }

=cut
