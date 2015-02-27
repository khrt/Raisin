
use strict;
use warnings;

use Test::More;

use Raisin;
use Raisin::Plugin;

subtest 'register' => sub {
    my $caller = caller;
    my $app = Raisin->new(caller => $caller);
    isa_ok $app, 'Raisin', 'app';

    my $p = Raisin::Plugin->new($app);
    isa_ok $p, 'Raisin::Plugin', 'p';

    $p->register(hello => sub { 'hello' });

    ok $p->build, 'build';

    ok $app->can('hello'), 'registered';
    is $app->hello, 'hello', 'exec';
};


done_testing;
