package Raisin::Logger;

use strict;
use warnings;

my $FH = *STDERR;

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self;
}

sub log {
    my ($self, %args) = @_;
    printf $FH '%s %s', uc($args{level}), $args{message};
}

1;

__END__

=head1 NAME

Raisin::Logger - Default logger for Raisin.

=head1 SYNOPSIS

    my $logger = Raisin::Logger->new;
    $logger->log(info => 'Hello, world!');

=head1 DESCRIPTION

Simple logger for Raisin.

=head1 METHODS

=head2 log

Accept's two parameters: C<level> and C<message>.

=cut
