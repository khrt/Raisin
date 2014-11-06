package Raisin::Attributes;

use strict;
use warnings;

sub import {
    my $class = shift;
    my $caller = caller;

    return if $class ne __PACKAGE__;

    no strict 'refs';
    no warnings 'redefine';

    *{"${caller}::has"} = sub { __has($caller, @_) };
    #*{"${caller}::has_many"} = sub { __has_many($caller, @_) };
}

sub __has_many {
    my ($class, @names) = @_;
    for (@names) {
        __has($class, $_);
    }
}

sub __has {
    my ($class, $name, $default) = @_;

    my $attr = sub {
        my ($self, $value) = @_;
        $self->{$name} = $value if defined $value;
        $self->{$name} // $default;
    };

    no strict 'refs';
    *{"${class}::$name"} = $attr;
}

1;

__END__

=head1 NAME

Raisin::Attributes - Simple attributes accessors for Raisin.

=head1 SYNOPSIS

    use Raisin::Attributes;

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

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
