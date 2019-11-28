#!perl
#PODNAME: Raisin::Logger
#ABSTRACT: Default logger for Raisin.

use strict;
use warnings;

package Raisin::Logger;

my $FH = *STDERR;

sub new { bless {}, shift }

sub log {
    my ($self, %args) = @_;
    printf $FH '%s %s', uc($args{level}), $args{message};
}

1;

__END__

=head1 SYNOPSIS

    my $logger = Raisin::Logger->new;
    $logger->log(info => 'Hello, world!');

=head1 DESCRIPTION

Simple logger for Raisin.

=head1 METHODS

=head2 log

Accept's two parameters: C<level> and C<message>.

=cut
