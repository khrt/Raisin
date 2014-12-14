
use strict;
use warnings;

use Data::Dumper;
use FindBin '$Bin';
use Plack::Util;
use Test::More;

use lib "$Bin/../../../lib";

use Raisin;
use Raisin::Plugin::Logger;

my %LOGGER_MESSAGE = (key => 'value', data => [0, 1]);

my @CASES = (
    {
        logger => 'Raisin::Logger',
        input => { level => 'error', message => 'some error' },
        expected => 'ERROR some error',
    },
    {
        logger => 'Raisin::Logger',
        input => { level => 'debug', message => \%LOGGER_MESSAGE },
        expected => 'DEBUG ' . Dumper(\%LOGGER_MESSAGE),
    },

    {
        logger => 'Log::Dispatch',
        input => { level => 'error', message => 'some error' },
        expected => 'ERROR some error',
    },
    {
        logger => 'Log::Dispatch',
        input => { level => 'debug', message => \%LOGGER_MESSAGE },
        expected => 'DEBUG ' . Dumper(\%LOGGER_MESSAGE),
    },
);

sub _make_object {
    my $object = shift;

    my $caller = caller;
    my $app = Raisin->new(caller => $caller);

    my $module = Raisin::Plugin::Logger->new($app);
    $module->build($object eq 'Raisin::Logger' ? (fallback => 1) : ());

    $app;
}

sub _reset_object {
    no strict 'refs';

    for my $pkg (qw(main Raisin)) {
        *{"${pkg}::log"} = 0;
        #delete ${$pkg}::{log};
    }
}

subtest 'build' => sub {
    plan skip_all => 'NA';
#    my %uniq = map { $_->{logger} => 1 } @CASES;
#    my @loggers = map { $_ } keys %uniq;
#
#    for my $logger (@loggers) {
#        subtest $logger => sub {
#            my $app = _make_object($logger);
#
#            my $path = "$logger.pm";
#            $path =~ s#::#/#g;
#
#            ok $INC{$path}, "load $logger";
#            ok $app->can('log'), "app can log";
#
#            my $main_can = main->can('log');
#            ok $main_can, "main can log";
#        };
#
#        _reset_object();
#    }
};

subtest 'message' => sub {
    plan skip_all => 'NA';
#    _reset_object();
#    for my $case (@CASES) {
#        my $app = _make_object($case->{logger});
#
#        $app->log($case->{level}, $case->{message});
#
#        _reset_object();
#    }
};

done_testing;
