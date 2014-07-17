
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Logger;

my $OUT;

close STDERR;
open STDERR, '>', \$OUT or BAIL_OUT("Can't open STDERR $!");

my $logger = Raisin::Logger->new;

$logger->log(level => 'error', message => 'hello!');
is $OUT, 'ERROR hello!', 'hello!';

close STDERR;

done_testing;
