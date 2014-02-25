package Raisin::Plugin::Logger;

use strict;
use warnings;

use base 'Raisin::Plugin';

use Log::Dispatch;
use POSIX qw(strftime);
use Time::HiRes qw(time);

sub build {
    my ($self, @args) = @_;
    my $logger = $self->{logger} = Log::Dispatch->new(@args);

    # Register a few levels
    my @levels_to_register = qw/debug info error/;

    # Build the registration hash
    my %LEVELS = map {
        my $level = $_;
        $level => sub {
            shift if ref($_[0]);
            $self->message($level, @_);
        };
    } @levels_to_register;

    # Register the log levels
    $self->register(%LEVELS);

    # Also register the message method as 'logger'
    $self->register(logger => sub {
        shift if ref($_[0]);
        $self->message(@_);
    });
}

sub message {
    my ($self, $level, @messages) = @_;

    for (@messages) {
        my $t = time;
        my $date = strftime "%Y-%m-%d %H:%M:%S", localtime $t;
        $date .= sprintf ".%03d", ($t - int($t)) * 1000;

        $self->{logger}->log(
            level   => $level,
            message => sprintf("%s - %s - %s\n",
                $date, $level, ref($_) ? Dumper($_) : $_)
        );
    }
}

1;

### L<Kelp::Plugin::Logger>
