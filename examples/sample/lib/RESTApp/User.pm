package RESTApp::User;

use strict;
use warnings;

use Raisin::API;
use Raisin::Types;
use UseCase::User;

namespace user => sub {
    params [
        #required/optional => [name, type, default, values]
        optional => ['start', 'Raisin::Types::Integer', 0, qr/^\d+$/],
        optional => ['count', 'Raisin::Types::Integer', 10, qr/^\d+$/],
    ],
    get => sub {
        my $params = shift;
        my @users = UseCase::User::list(%$params);
        { data => RESTApp::paginate(\@users, $params) }
    };

    params [
        required => ['name', 'Raisin::Types::String'],
        required => ['password', 'Raisin::Types::String'],
        optional => ['email', 'Raisin::Types::String', undef, qr/prev-regex/],
    ],
    post => sub {
        my $params = shift;
        { success => UseCase::User::create(%$params) }
    };

    route_param id => 'Raisin::Types::Integer',
    sub {
        get sub {
            my $params = shift;
            { data => UseCase::User::show($params->{id}) }
        };

        params [
            optional => ['password', 'Raisin::Types::String'],
            optional => ['email', 'Raisin::Types::String', undef, qr/next-regex/],
        ],
        put => sub {
            my $params = shift;
            { data => UseCase::User::edit($params->{id}, $params) }
        };

        namespace bump => sub {
            get sub {
                my $params = shift;
                { data => UseCase::User::show($params->{id})->{bumped} }
            };

            put sub {
                my $params = shift;
                { success => UseCase::User::bump($params->{id}) }
            };
        };
    };
};

1;
