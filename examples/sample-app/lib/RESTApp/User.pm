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
        optional('start', type => Int, default => 0, desc => 'Pager start'),
        optional('count', type => Int, default => 10, desc => 'Pager count'),
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
        requires('name', type => Str, desc => 'User name'),
        requires('password', type => Str, desc => 'User password'),
        optional('email', type => Str, default => undef, desc => 'User email'),
    );
    post sub {
        my $params = shift;
        { success => UseCase::User::create(%$params) }
    };

    params(
        requires('id', type => Int, desc => 'User ID'),
    );
    route_param id => sub {
        summary 'Show a user';
        get sub {
            my $params = shift;
            { data => UseCase::User::show($params->{id}) }
        };

        summary 'Edit a user';
        params(
            optional('password', type => Str, desc => 'User password'),
            optional('email', type => Str, desc => 'User email'),
        );
        put sub {
            my $params = shift;
            { data => UseCase::User::edit($params->{id}, %$params) }
        };
        summary 'Edit a user';
        params(
            optional('password', type => Str, desc => 'User password'),
            optional('email', type => Str, desc => 'User email'),
        );
        patch sub {
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
            summary 'Bump a user';
            tags 'users', 'bump';
            patch sub {
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
