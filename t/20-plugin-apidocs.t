
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../lib";

use Raisin::Plugin::APIDocs;
use Raisin::Routes;
use Raisin::Types;
use Raisin;

my $a = Raisin->new;
$a->api_version('1.23');

my $r = $a->{routes};

$r->add(
    GET => '/person/:id',
    params => [
        required => ['name', 'Raisin::Types::String'],
        optional => ['zip', 'Raisin::Types::Integer'],
    ],
    sub { 'GET' }
);
$r->add(
    POST => '/person',
    params => [
        optional => ['email', 'Raisin::Types::String'],
    ],
    sub { 'POST' }
);

$r->add(
    GET => '/address',
    params => [
        required => ['street', 'Raisin::Types::String'],
        required => ['house_num', 'Raisin::Types::String'],
    ],
    sub { 'POST' }
);
$r->add(
    POST => '/address',
    params => [
        required => ['street', 'Raisin::Types::String'],
        required => ['house_num', 'Raisin::Types::String'],
        required => ['apartment', 'Raisin::Types::String'],
    ],
    sub { 'POST' }
);

my $i = Raisin::Plugin::APIDocs->new($a);
ok $i->build_api_docs;

done_testing;
