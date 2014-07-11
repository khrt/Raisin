
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
        required => { name => 'name', type => Str },
        optional => { name => 'zip', type => Int },
    ],
    sub { 'GET' }
);
$r->add(
    POST => '/person',
    params => [
        optional => { name => 'email', type => Str },
    ],
    sub { 'POST' }
);

$r->add(
    GET => '/address',
    params => [
        required => { name => 'street', type => Str },
        required => { name => 'house_num', type => Str },
    ],
    sub { 'POST' }
);
$r->add(
    POST => '/address',
    params => [
        required => { name => 'street', type => Str },
        required => { name => 'house_num', type => Str },
        required => { name => 'apartment', type => Str },
    ],
    sub { 'POST' }
);

my $i = Raisin::Plugin::APIDocs->new($a);
ok $i->build_api_docs;

done_testing;
