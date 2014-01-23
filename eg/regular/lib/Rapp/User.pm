package Rapp::User;

use strict;
use warnings;

use Raisin::DSL;
use Raisin::Types;

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
        optional => ['count', $Raisin::Types::Integer, 10, qr/^\d+$/],
    ],
    sub {
        my $params = shift;
        my @users = map { $USERS{$_} } sort { $a <=> $b } keys %USERS;
        my ($start, $count) = ($params->{start}, $params->{count});

        $start = $start > scalar @users ? scalar @users : $start;
        $count = $count > scalar @users ? scalar @users : $count;

        res->json;
        @users[$start, $count];
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
        get sub {
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
            for (qw(password email)) {
                $USERS{ $params->{id} }{$_} = $params->{$_};
            }
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

1;
