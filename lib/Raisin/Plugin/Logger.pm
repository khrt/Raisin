#!perl
#PODNAME: Raisin::Plugin::Logger
#ABSTRACT: Logger plugin for Raisin.

use strict;
use warnings;

package Raisin::Plugin::Logger;

use parent 'Raisin::Plugin';

use Carp qw(carp);
use Data::Dumper qw(Dumper);
use POSIX qw(strftime);
use Plack::Util;
use Time::HiRes qw(time);

sub build {
    my ($self, %args) = @_;

    my $logger = $args{fallback} ? 'Raisin::Logger' : 'Log::Dispatch';

    my $obj;
    eval { $obj = Plack::Util::load_class($logger) } || do {
        carp 'Can\'t load `Log::Dispatch`. Fallback to `Raisin::Logger`!';
        $obj = Plack::Util::load_class('Raisin::Logger');
    };

    $self->{logger} = $obj->new(%args);

    $self->register(log => sub {
        shift if ref($_[0]);
        $self->message(@_);
    });
}

sub message {
    my ($self, $level, $message, @args) = @_;

    my $t = time;
    my $time = strftime '%Y-%m-%dT%H:%M:%S', localtime $t;
    $time .= sprintf '.%03d', ($t - int($t)) * 1000;

    $message = ref($message) ? Dumper($message) : $message;

    $self->{logger}->log(
        level   => $level,
        message => sprintf "$time $message\n", @args,
    );
}

1;

__END__

=head1 SYNOPSIS

    plugin 'Logger';
    logger(info => 'Hello!');

=head1 DESCRIPTION

Provides C<log> method which is an alias for L<Log::Dispatch>
or L<Raisin::Logger> C<log> method.

    $self->{logger}->log(
        level   => $level,
        message => "$ts: $str\n",
    );

=cut
