#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use List::Util qw(max);

use lib "$FindBin::Bin/../../lib";

use Raisin::DSL;
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

# /user
namespace user => sub {
    # list all users
    get params => [
        #required/optional => [name, type, default, values]
        optional => ['start', $Raisin::Types::Integer, 0, qr/^\d+$/],
        optional => ['count', $Raisin::Types::Integer, 0, qr/^\d+$/],
    ],
    sub {
        res->json;
        [map { $USERS{$_} } keys %USERS]
    };

    # create new user
    post params => [
        required => ['name', $Raisin::Types::String],
        required => ['password', $Raisin::Types::String],
        optional => ['email', $Raisin::Types::String, undef, qr/prev-regex/],
    ],
    sub {
        my $params = shift;

        my $id = max(keys %USERS) + 1;

        $USERS{$id} = $params;

        res->json;
        { success => 1 }
    };

    # /user/<id>
    route_param id => $Raisin::Types::Integer,
    sub {
        # get user
#        get sub {
#            my $params = shift;
#            res->json;
#            { data => $USERS{ $params->{id} } || 'Nothing found!' }
#        };
        get params => [
            optional => ['view', $Raisin::Types::String, '', qr/all|one/],
        ],
        sub {
            my $params = shift;
            res->json;
            { data => $USERS{ $params->{id} } || 'Nothing found!' }
        };

        # edit user
        put params => [
            optional => ['password', $Raisin::Types::String],
            optional => ['email', $Raisin::Types::String, undef, qr/next-regex/],
        ],
        sub {
            my $params = shift;

            $USERS{ $params->{id} } = { map { $_ => $params->{$_} } qw(password email) };

            res->json;
            { success => 1 }
        };

        # /user/<id>/bump
        namespace bump => sub {
            # get bump count
            get sub {
                my $params = shift;

                res->json;
                { data => $USERS{ $params->{id} }{bumped} }
            };

            # bump user
            put sub {
                my $params = shift;

                $USERS{ $params->{id} }{bumped}++;

                res->json;
                { success => 1 }
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
