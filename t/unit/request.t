
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin;
use Raisin::Request;

my $caller = caller;
my $app = Raisin->new(caller => $caller);

ok 1, 'skip';

#subtest 'deserialize' => sub {
#    #subtest 'body' => sub {};
#    #subtest 'form' => sub {};
#    #subtest 'path' => sub {};
#};
#
#subtest 'prepare_params' => sub {
#};

done_testing;
