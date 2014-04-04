package Rapp::User;

use strict;
use warnings;

use Raisin::API;
use Raisin::Types;

# USERS
my %USERS = (
    1 => {
        name => 'Darth Wader',
        password => 'empire',
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
    params [
        #required/optional => [name, type, default, values]
        optional => ['start', 'Raisin::Types::Integer', 0, qr/^\d+$/],
        optional => ['count', 'Raisin::Types::Integer', 10, qr/^\d+$/],
    ],
    get => sub {
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
    params [
        required => ['name', 'Raisin::Types::String'],
        required => ['password', 'Raisin::Types::String'],
        optional => ['email', 'Raisin::Types::String', undef, qr/prev-regex/],
    ],
    post => sub {
        my $params = shift;

        my $id = max(keys %USERS) + 1;
        $USERS{$id} = $params;

        { success => 1 }
    };

    # /user/<id>
    route_param id => 'Raisin::Types::Integer',
    sub {
        # get user
        get sub {
            my $params = shift;
            { data => $USERS{ $params->{id} } || 'Nothing found!' }
        };

        # edit user
        params [
            optional => ['password', 'Raisin::Types::String'],
            optional => ['email', 'Raisin::Types::String', undef, qr/next-regex/],
        ],
        put => sub {
            my $params = shift;
            for (qw(password email)) {
                $USERS{ $params->{id} }{$_} = $params->{$_};
            }
            { success => 1 }
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
                $USERS{ $params->{id} }{bumped}++;
                { success => 1 }
            };
        };
    };
};

1;
