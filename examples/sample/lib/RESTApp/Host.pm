package RESTApp::Host;

use strict;
use warnings;

use Raisin::API;
use Raisin::Types;
use UseCase::Host;

namespace host => sub {
    params [
        optional => ['start', 'Raisin::Types::Integer', 0, qr/^\d+$/],
        optional => ['count', 'Raisin::Types::Integer', 10, qr/^\d+$/],
    ],
    get => sub {
        my $params = shift;
        my @hosts = UseCase::Host::list(%$params);
        { data => RESTApp::paginate(\@hosts, $params) }
    };

    params [
        required => ['name', 'Raisin::Types::String'],
        required => ['user_id', 'Raisin::Types::Integer'],
        optional => ['state', 'Raisin::Types::String']
    ],
    post => sub {
        my $params = shift;
        { success => UseCase::Host::create(%$params) }
    };

    route_param id => 'Raisin::Types::Integer',
    sub {
        get sub {
            my $params = shift;
            { data => UseCase::Host::show($params->{id}) }
        };

        params [
            required => ['state', 'Raisin::Types::String'],
        ],
        put => sub {
            my $params = shift;
            { data => UseCase::Host::edit($params->{id}, $params) }
        };

        delete => sub {
            my $params = shift;
            { success => UseCase::Host::delete($params->{id}) }
        }
    };
};

1;
