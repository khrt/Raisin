package RESTApp::User;

use strict;
use warnings;

use Raisin::API;
use UseCase::User;

use Types::Standard qw(Int Str);

namespace user => sub {
    params [
        #required/optional => [name, type, default, values]
        optional => ['start', Int, 0, qr/^\d+$/],
        optional => ['count', Int, 10, qr/^\d+$/],
    ],
    get => sub {
        my $params = shift;
        my @users = UseCase::User::list(%$params);
        { data => RESTApp::paginate(\@users, $params) }
    };

    params [
        required => ['name', Str],
        required => ['password', Str],
        optional => ['email', Str, undef, qr/prev-regex/],
    ],
    post => sub {
        my $params = shift;
        { success => UseCase::User::create(%$params) }
    };

    route_param id => Int,
    sub {
        get sub {
            my $params = shift;
            { data => UseCase::User::show($params->{id}) }
        };

        params [
            optional => ['password', Str],
            optional => ['email', Str, undef, qr/next-regex/],
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
