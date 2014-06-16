#!/usr/bin/env perl

use strict;
use warnings;

use DDP;
use FindBin;
use List::Util qw(max);

use lib "$FindBin::Bin/../../lib";

use Raisin::API;
use Types::Standard qw(Int Str);

#middleware '+Plack::Middleware::ContentLength';
middleware 'Runtime';
#middleware '+Plack::Middleware::SimpleLogger';

params [
    optional => ['password', Str, undef, qr/qwerty/],
    optional => ['email', Str, 'NA'],
    optional => ['phone', Int, 'NA'],
],
get => sub {
    my $params = shift;
    $params;
};

params [
    optional => ['password', Str, undef, qr/ytrewq/],
    optional => ['email', Str, 'AN'],
    optional => ['phone', Int, 'NA'],
],
post => sub {
    my $params = shift;
    $params;
};

run;
