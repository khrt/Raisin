
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Logger;

my @CASES = (
    {
        input => { level => 'error', message => 'some error' },
        expected => 'ERROR some error',
    },
    {
        input => { level => 'warn', message => 'some warn' },
        expected => 'WARN some warn',
    },
    {
        input => { level => 'debug', message => 'some debug' },
        expected => 'DEBUG some debug',
    },
);

subtest 'log' => sub {
    my $logger = Raisin::Logger->new;
    isa_ok $logger, 'Raisin::Logger', 'logger';

    close STDERR;
    for my $case (@CASES) {
        my $OUT;
        open STDERR, '>', \$OUT or BAIL_OUT("Can't open STDERR $!");

        $logger->log(level => $case->{input}{level}, message => $case->{input}{message});
        is $OUT, $case->{expected}, $case->{input}{level};

        close STDERR;
    }
};

done_testing;
