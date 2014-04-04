#!/usr/bin/env perl

use strict;
use warnings;

use DDP;
use FindBin;
use List::Util qw(max);

use lib "$FindBin::Bin/../../lib";

use Raisin::API;
use Raisin::Types;

#middleware '+Plack::Middleware::ContentLength';
middleware 'Runtime';
#middleware '+Plack::Middleware::SimpleLogger';

params [
    optional => ['password', 'Raisin::Types::String', undef, qr/qwerty/],
    optional => ['email', 'Raisin::Types::String', 'NA'],
],
get => sub {
    my $params = shift;
    $params;
};

params [
    optional => ['password', 'Raisin::Types::String', undef, qr/ytrewq/],
    optional => ['email', 'Raisin::Types::String', 'AN'],
],
post => sub {
    my $params = shift;
    $params;
};

run;
