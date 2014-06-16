package RESTApp::Host;

use strict;
use warnings;

use Raisin::API;
use UseCase::Host;

use Types::Standard qw(Int Str);

namespace host => sub {
    params [
        optional => ['start', Int, 0, qr/^\d+$/],
        optional => ['count', Int, 10, qr/^\d+$/],
    ],
    get => sub {
        my $params = shift;
        my @hosts = UseCase::Host::list(%$params);
        { data => RESTApp::paginate(\@hosts, $params) }
    };

    params [
        required => ['name', Str],
        required => ['user_id', Int],
        optional => ['state', Str]
    ],
    post => sub {
        my $params = shift;
        { success => UseCase::Host::create(%$params) }
    };

    route_param id => Int,
    sub {
        get sub {
            my $params = shift;
            { data => UseCase::Host::show($params->{id}) }
        };

        params [
            required => ['state', Str],
        ],
        put => sub {
            my $params = shift;
            { data => UseCase::Host::edit($params->{id}, $params) }
        };

        del sub {
            my $params = shift;
            { success => UseCase::Host::delete($params->{id}) }
        }
    };
};

1;
