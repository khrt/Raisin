package Raisin::Types::Base;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    @$self{keys %args} = values %args;
    $self;
}

sub default { shift->{default} }

sub check {
    my ($self, $value) = @_;
    $self->{check}->($self, $value);
}

sub in { shift->{in} }
sub regex { shift->{regex} }

1;
