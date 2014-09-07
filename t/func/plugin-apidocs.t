
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Plugin::Swagger;
use Raisin::Routes;
use Types::Standard qw(Int Str);
use Raisin;

my $a = Raisin->new;
$a->api_version('1.23');

my $r = $a->{routes};

$r->add(
    method => 'GET',
    path => '/person/:id',
    params => [
        required => { name => 'name', type => Str },
        optional => { name => 'zip', type => Int },
    ],
    code => sub { 'GET' }
);
$r->add(
    method => 'POST',
    path => '/person',
    params => [
        optional => { name => 'email', type => Str },
    ],
    code => sub { 'POST' }
);

$r->add(
    method => 'GET',
    path => '/address',
    params => [
        required => { name => 'street', type => Str },
        required => { name => 'house_num', type => Str },
    ],
    code => sub { 'POST' }
);
$r->add(
    method => 'POST',
    path => '/address',
    params => [
        required => { name => 'street', type => Str },
        required => { name => 'house_num', type => Str },
        required => { name => 'apartment', type => Str },
    ],
    code => sub { 'POST' }
);

my $i = Raisin::Plugin::Swagger->new($a);
ok $i->build_api_docs;

done_testing;
