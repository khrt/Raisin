package Rapp::Host;

use strict;
use warnings;

use Raisin::DSL;

# USERS
my %HOSTS = (
    1 => {
        name => 'deathstart.com',
        user_id => 1,
        state => 'active',
    },
    2 => {
        name => 'jedi.com',
        user_id => 2,
        state => 'active',
    },
    3 => {
        name => 'naboo.com',
        user_id => 2,
        state => 'inactive',
    },
);

# /host
namespace host => sub {
    # list all hosts
    get params => [
        #required/optional => [name, type, default, values]
        optional => ['start', $Raisin::Types::Integer, 0, qr/^\d+$/],
        optional => ['count', $Raisin::Types::Integer, 10, qr/^\d+$/],
    ],
    sub {
        my $params = shift;
        my @hosts = map { $HOSTS{$_} } sort { $a <=> $b } keys %HOSTS;
        my ($start, $count) = ($params->{start}, $params->{count});

        $start = $start > scalar @hosts ? scalar @hosts : $start;
        $count = $count > scalar @hosts ? scalar @hosts : $count;

        res->json;
        @hosts[$start, $count];
    };

    # create new host
    post params => [
        required => ['name', $Raisin::Types::String],
        required => ['user_id', $Raisin::Types::Integer],
    ],
    sub {
        my $params = shift;

        my $id = max(keys %HOSTS) + 1;
        $HOSTS{$id} = $params;

        res->json;
        { success => 1 }
    };

    # /host/<id>
    route_param id => $Raisin::Types::Integer,
    sub {
        # get host
        get sub {
            my $params = shift;
            res->json;
            { data => $HOSTS{ $params->{id} } || 'Nothing found!' }
        };

        # edit host
        put params => [
            required => ['state', $Raisin::Types::String],
        ],
        sub {
            my $params = shift;
            $HOSTS{ $params->{id} }{state} = $params->{state};
            res->json;
            { success => 1 }
        };
    };
};

1;
