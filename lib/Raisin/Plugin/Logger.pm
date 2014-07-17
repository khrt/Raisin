package Raisin::Plugin::Logger;

use strict;
use warnings;

use base 'Raisin::Plugin';

use Carp qw(carp);
use POSIX qw(strftime);
use Plack::Util;
use Time::HiRes qw(time);

sub build {
    my ($self, %args) = @_;

    my $logger = $args{fallback} ? 'Raisin::Logger' : 'Log::Dispatch';

    my $obj;
    eval { $obj = Plack::Util::load_class($logger) } || do {
        carp 'Can\'t load `Log::Dispatch. Fallback to `Raisin::Logger`!';
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
    my $ts = strftime "%Y-%m-%dT%H:%M:%S", localtime $t;
    $ts .= sprintf ".%03d", ($t - int($t)) * 1000;

    my $str = ref($message) ? Dumper($message) : $message;

    $self->{logger}->log(
        level   => $level,
        message => "$ts $str\n",
    );
}

1;

__END__

=head1 NAME

Raisin::Plugin::Logger - Logger plugin for Raisin.

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
