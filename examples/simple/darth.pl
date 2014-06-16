#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Raisin::API;
use Types::Standard qw(Int Str);

my %USERS = (
    1 => {
        name => 'Darth Wader',
        password => 'deathstar',
        email => 'darth@deathstar.com',
    },
    2 => {
        name => 'Luke Skywalker',
        password => 'qwerty',
        email => 'l.skywalker@jedi.com',
    },
);

namespace user => sub {
    params [
        #required/optional => [name, type, default, regex]
        optional => ['start', Int, 0],
        optional => ['count', Int, 10],
    ],
    get => sub {
        my $params = shift;

        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;

        my $max_count = scalar(@users) - 1;
        my $start = $params->{start} > $max_count ? $max_count : $params->{start};
        my $count = $params->{count} > $max_count ? $max_count : $params->{count};

        my @slice = @users[$start .. $count];
        { data => \@slice }
    };

    get 'all' => sub {
        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;
        { data => \@users }
    };

    params [
        required => ['name', Str],
        required => ['password', Str],
        optional => ['email', Str, undef, qr/.+\@.+/],
    ],
    post => sub {
        my $params = shift;

        my $id = max(keys %USERS) + 1;
        $USERS{$id} = $params;

        { success => 1 }
    };

    route_param id => Int,
    sub {
        get sub {
            my $params = shift;
            $USERS{ $params->{id} };
        };
    };
};

run;
