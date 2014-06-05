package Raisin::Plugin::Logger;

use strict;
use warnings;

use base 'Raisin::Plugin';

use POSIX qw(strftime);
use Plack::Util;
use Time::HiRes qw(time);

sub build {
    my ($self, %args) = @_;

    my $module = 'Log::Dispatch';

    if (delete $args{fallback}) {
        $module = qw(Raisin::Logger);
    }

    my $class = Plack::Util::load_class($module);

    $self->{logger} = $class->new(%args);

    $self->register(log => sub {
        shift if ref($_[0]);
        $self->message(@_);
    });
}

sub message {
    my ($self, $level, @messages) = @_;

    for (@messages) {
        my $t = time;
        my $ts = strftime "%d/%b/%Y %H:%M:%S", localtime $t;
        $ts .= sprintf ".%03d", ($t - int($t)) * 1000;

        my $str = ref($_) ? Dumper($_) : $_;

        $self->{logger}->log(
            level   => $level,
            message => "$ts: $str\n",
        );
    }
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
