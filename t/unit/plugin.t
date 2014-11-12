
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin;
use Raisin::Plugin;

my $caller = caller;
my $app = Raisin->new(caller => $caller);

my $p = Raisin::Plugin->new($app);
$p->register(hello => sub { 'hello' });

ok $app->can('hello'), 'registered';
is $app->hello, 'hello', 'exec';

done_testing;
