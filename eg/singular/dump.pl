#!/usr/bin/env perl

use strict;
use warnings;

use DDP;
use FindBin;
use List::Util qw(max);

use lib "$FindBin::Bin/../../lib"; # ->Raisin/lib

use Raisin::API;
use Raisin::Types;

my %USERS = (
    1 => {
        name => 'Darth Wader',
        password => 'death',
        email => 'darth@deathstar.com',
    },
    2 => {
        name => 'Luke Skywalker',
        password => 'qwerty',
        email => 'l.skywalker@jedi.com',
    },
);

#middleware '+Plack::Middleware::ContentLength';
middleware 'Runtime';
#middleware '+Plack::Middleware::SimpleLogger';

get params => [
    optional => ['password', $Raisin::Types::String, undef, qr/qwerty/],
    optional => ['email', $Raisin::Types::String, 'NA'],
],
sub {
    my $params = shift;
    p $params;

    \%USERS
};

post params => [
    optional => ['password', $Raisin::Types::String, undef, qr/ytrewq/],
    optional => ['email', $Raisin::Types::String, 'AN'],
],
sub {
    my $params = shift;
    p $params;

    \%USERS
};

run;
