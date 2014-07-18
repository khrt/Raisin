package RESTApp::User;

use strict;
use warnings;

use Raisin::API;
use UseCase::User;

use Types::Standard qw(Int Str);

resource user => sub {
    params [
        optional => { name => 'start', type => Int, default => 0, desc => 'Pager start' },
        optional => { name => 'count', type => Int, default => 10, desc => 'Pager count' },
    ],
    desc => 'List users',
    get => sub {
        my $params = shift;
        my @users = UseCase::User::list(%$params);
        { data => paginate(\@users, $params) }
    };

    desc 'List all users',
    get => 'all' => sub {
        my $params = shift;
        my @users = UseCase::User::list(%$params);
        { data => \@users }
    };

    params [
        required => { name => 'name', type => Str, desc => 'User name' },
        required => { name => 'password', type => Str, desc => 'User password' },
        optional => { name => 'email', type => Str, default => undef, desc => 'User email' },
    ],
    desc => 'Create new user',
    post => sub {
        my $params = shift;
        { success => UseCase::User::create(%$params) }
    };

    route_param id => Int,
    sub {
        desc 'Show user',
        get => sub {
            my $params = shift;
            { data => UseCase::User::show($params->{id}) }
        };

        params [
            optional => { name => 'password', type => Str, desc => 'User password' },
            optional => { name => 'email', type => Str, desc => 'User email' },
        ],
        desc => 'Edit user',
        put => sub {
            my $params = shift;
            { data => UseCase::User::edit($params->{id}, %$params) }
        };

        resource bump => sub {
            desc 'Get bumps count',
            get => sub {
                my $params = shift;
                { data => UseCase::User::show($params->{id})->{bumped} }
            };

            desc 'Bump user',
            put => sub {
                my $params = shift;
                { success => UseCase::User::bump($params->{id}) }
            };
        };
    };
};

1;
