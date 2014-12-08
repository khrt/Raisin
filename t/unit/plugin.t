
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin;
use Raisin::Plugin;

subtest 'register' => sub {
    my $caller = caller;
    my $app = Raisin->new(caller => $caller);
    isa_ok $app, 'Raisin', 'app';

    my $p = Raisin::Plugin->new($app);
    isa_ok $p, 'Raisin::Plugin', 'p';

    $p->register(hello => sub { 'hello' });

    ok $app->can('hello'), 'registered';
    is $app->hello, 'hello', 'exec';
};


done_testing;
