package Rapp::Host;

use strict;
use warnings;

use Raisin::API;
use Types::Standard qw(Int Str);

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
    params [
        #required/optional => [name, type, default, values]
        optional => ['start', Int, 0, qr/^\d+$/],
        optional => ['count', Int, 10, qr/^\d+$/],
    ],
    get => sub {
        my $params = shift;
        my ($start, $count) = ($params->{start}, $params->{count});

        my @hosts
            = map { { id => $_, %{ $HOSTS{$_} } } }
              sort { $a <=> $b } keys %HOSTS;

        $start = $start > scalar @hosts ? scalar @hosts : $start;
        $count = $count > scalar @hosts ? scalar @hosts : $count;

        my @slice = @hosts[$start .. $count];
        { data => \@slice }
    };

    # create new host
    params [
        required => ['name', Str],
        required => ['user_id', Int],
    ],
    post => sub {
        my $params = shift;

        my $id = max(keys %HOSTS) + 1;
        $HOSTS{$id} = $params;

        { success => 1 }
    };

    # /host/<id>
    route_param id => Int,
    sub {
        # get host
        get sub {
            my $params = shift;
            { data => $HOSTS{ $params->{id} } || 'Nothing found!' }
        };

        # edit host
        params [
            required => ['state', Str],
        ],
        put => sub {
            my $params = shift;
            $HOSTS{ $params->{id} }{state} = $params->{state};
            { success => 1 }
        };
    };
};

1;
