
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../lib";

use Raisin::Routes;
use Raisin::Routes::Endpoint;
use Raisin::Types;

my $r = Raisin::Routes->new;

ok $r->add(POST => '/dump', sub {'DUMP'}), 'add DUMP';
ok $r->add(
    POST   => '/person',
    params => [
        requires => ['name', $Raisin::Types::String],
        optional => ['email', $Raisin::Types::String]
    ],
    sub {'PERSON'}
    ),
    'add PERSON';

is $r->list->{POST}{'/person'}, 2, 'list';

is_deeply $r->cache, {}, 'empty cache';

ok my $subs = $r->find('POST', '/person'), 'find';
is $subs->[0]->code->(), 'PERSON', 'execute';

is ref $r->cache->{'post:/person'}, 'ARRAY', 'cached';

done_testing;
