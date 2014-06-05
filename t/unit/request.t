
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin;
use Raisin::Request;

my $caller = caller;
my $app = Raisin->new(caller => $caller);

subtest 'deserialize' => sub {
    ok 1;
};

subtest 'prepare_params' => sub {
    ok 1;
};

done_testing;
