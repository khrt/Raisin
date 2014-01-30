#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use List::Util qw(max);

use lib "$FindBin::Bin/../../lib"; # ->Raisin/lib

use Raisin::DSL;

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

get sub { \%USERS };

run;
