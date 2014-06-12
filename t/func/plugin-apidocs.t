
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Plugin::APIDocs;
use Raisin::Routes;
use Types::Standard qw(Int Str);
use Raisin;

my $a = Raisin->new;
$a->api_version('1.23');

my $r = $a->{routes};

$r->add(
    GET => '/person/:id',
    params => [
        required => ['name', Str],
        optional => ['zip', Int],
    ],
    sub { 'GET' }
);
$r->add(
    POST => '/person',
    params => [
        optional => ['email', Str],
    ],
    sub { 'POST' }
);

$r->add(
    GET => '/address',
    params => [
        required => ['street', Str],
        required => ['house_num', Str],
    ],
    sub { 'POST' }
);
$r->add(
    POST => '/address',
    params => [
        required => ['street', Str],
        required => ['house_num', Str],
        required => ['apartment', Str],
    ],
    sub { 'POST' }
);

my $i = Raisin::Plugin::APIDocs->new($a);
ok $i->build_api_docs;

done_testing;
