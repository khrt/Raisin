package RESTApp::User;

use strict;
use warnings;

use Raisin::API;
use UseCase::User;

use Types::Standard qw(Int Str);

desc 'Operations about user';
resource users => sub {
    summary 'List users';
    params(
        optional => { name => 'start', type => Int, default => 0, desc => 'Pager start' },
        optional => { name => 'count', type => Int, default => 10, desc => 'Pager count' },
    );
    get sub {
        my $params = shift;
        my @users = UseCase::User::list(%$params);
        { data => RESTApp::paginate(\@users, $params) }
    };

    summary 'List all users';
    get 'all' => sub {
        my $params = shift;
        my @users = UseCase::User::list(%$params);
        { data => \@users }
    };

    summary 'Create a new user';
    params(
        required => { name => 'name', type => Str, desc => 'User name' },
        required => { name => 'password', type => Str, desc => 'User password' },
        optional => { name => 'email', type => Str, default => undef, desc => 'User email' },
    );
    post sub {
        my $params = shift;
        { success => UseCase::User::create(%$params) }
    };

    params(
        requires => { name => 'id', type => Int, desc => 'User ID' },
    );
    route_param id => sub {
        summary 'Show a user';
        get sub {
            my $params = shift;
            { data => UseCase::User::show($params->{id}) }
        };

        summary 'Edit a user';
        params(
            optional => { name => 'password', type => Str, desc => 'User password' },
            optional => { name => 'email', type => Str, desc => 'User email' },
        );
        put sub {
            my $params = shift;
            { data => UseCase::User::edit($params->{id}, %$params) }
        };

        desc 'Bump a user';
        resource bump => sub {
            summary 'Get bumps count';
            tags 'users', 'bump';
            get sub {
                my $params = shift;
                { data => UseCase::User::show($params->{id})->{bumped} }
            };

            summary 'Bump a user';
            tags 'users', 'bump';
            put sub {
                my $params = shift;
                { success => UseCase::User::bump($params->{id}) }
            };
        };

        summary 'Delete a user';
        del sub {
            my $params = shift;
            { success => UseCase::User::remove($params->{id}) }
        }
    };
};

1;
