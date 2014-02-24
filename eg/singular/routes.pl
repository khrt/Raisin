#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use List::Util qw(max);

use lib "$FindBin::Bin/../../lib"; # ->Raisin/lib

use Raisin::API;
use Raisin::Types;

# GET  /user
# POST /user
# GET  /user/<id>
# PUT  /user/<id>
# GET  /user/<id>/bump
# PUT  /user/<id>/bump

# USERS
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

plugin 'APIDocs';
plugin 'Logger', outputs => [['Screen', min_level => 'debug']];
api_format 'YAML';

# /user
namespace user => sub {
    # list all users
    get params => [
        #required/optional => [name, type, default, regex]
        optional => ['start', $Raisin::Types::Integer, 0],
        optional => ['count', $Raisin::Types::Integer, 10],
    ],
    sub {
        my $params = shift;
        my ($start, $count) = ($params->{start}, $params->{count});

        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;

        $start = $start > scalar @users ? scalar @users : $start;
        $count = $count > scalar @users ? scalar @users : $count;

        my @slice = @users[$start .. $count];
        { data => \@slice }
    };

    # create new user
    post params => [
        required => ['name', $Raisin::Types::String],
        required => ['password', $Raisin::Types::String],
        optional => ['email', $Raisin::Types::String, undef, qr/[^@]@[^.].\w+/],
    ],
    sub {
        my $params = shift;

        my $id = max(keys %USERS) + 1;
        $USERS{$id} = $params;

        { success => $id }
    };

    # /user/<id>
    route_param id => $Raisin::Types::Integer,
    sub {
        # get user
        get sub {
            my $params = shift;
            { data => $USERS{ $params->{id} } || 'Nothing found!' }
        };

        # edit user
        put params => [
            optional => ['password', $Raisin::Types::String],
            optional => ['email', $Raisin::Types::String, undef, qr/[^@]@[^.].\w+/],
        ],
        sub {
            my $params = shift;

            my $updated = 0;
            for (grep { $params->{$_} } qw(password email)) {
                $USERS{ $params->{id} }{$_} = $params->{$_};
                $updated = 1;
            }

            { success => $updated }
        };

        # /user/<id>/bump
        namespace bump => sub {
            # get bump count
            get sub {
                my $params = shift;
                { data => $USERS{ $params->{id} }{bumped} }
            };

            # bump user
            put sub {
                my $params = shift;
                { success => ++$USERS{ $params->{id} }{bumped} }
            };
        };
    };
};

namespace failed => sub {
    get sub {
        res->status(409);
        { data => 'BROKEN!' }
    };
};

run;
