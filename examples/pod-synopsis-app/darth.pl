#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Status qw(:constants);
use List::Util qw(max);
use Raisin::API;
use Types::Standard qw(HashRef Any Int Str);

my %USERS = (
    1 => {
        first_name => 'Darth',
        last_name => 'Wader',
        password => 'deathstar',
        email => 'darth@deathstar.com',
    },
    2 => {
        first_name => 'Luke',
        last_name => 'Skywalker',
        password => 'qwerty',
        email => 'l.skywalker@jedi.com',
    },
);

middleware 'CrossOrigin',
    origins => '*',
    methods => [qw/DELETE GET HEAD OPTIONS PATCH POST PUT/],
    headers => [qw/accept authorization content-type api_key_token/];

plugin 'Swagger';

swagger_setup(
    title => 'A POD synopsis API',
    description => 'An example of API documentation.',
    #terms_of_service => '',

    contact => {
        name => 'Artur Khabibullin',
        url => 'http://github.com/khrt',
        email => 'rtkh@cpan.org',
    },

    license => {
        name => 'Perl license',
        url => 'http://dev.perl.org/licenses/',
    },
);

desc 'Users API';
resource users => sub {
    summary 'List users';
    params(
        optional('start', type => Int, default => 0, desc => 'Pager (start)'),
        optional('count', type => Int, default => 10, desc => 'Pager (count)'),
    );
    get sub {
        my $params = shift;

        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;

        my $max_count = scalar(@users) - 1;
        my $start = $params->{start} > $max_count ? $max_count : $params->{start};
        my $count = $params->{count} > $max_count ? $max_count : $params->{count};

        my @slice = @users[$start .. $count];
        { data => \@slice }
    };

    summary 'List all users at once';
    get 'all' => sub {
        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;
        { data => \@users }
    };

    # curl -X POST \
    #   -H "Content-Type: application/json" \
    #   -d '{"user":{"first_name":"Joe","last_name":"Doe","password":"qwerty","email":"joe@doe.com"}}'
    #   localhost:5000/users
    summary 'Create new user';
    params(
        requires('user', type => HashRef, desc => 'User object', group {
            requires('first_name', type => Str, desc => 'First name'),
            requires('last_name', type => Str, desc => 'Last name'),
            requires('password', type => Str, desc => 'User password'),
            optional('email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email'),
        }),
    );
    post sub {
        my $params = shift;

        my $id = max(keys %USERS) + 1;
        $USERS{$id} = $params->{user};

        res->status(HTTP_CREATED);
        { success => 1 }
    };

    desc 'Actions on the user';
    params requires('id', type => Int, desc => 'User ID');
    route_param 'id' => sub {
        summary 'Show user';
        get sub {
            my $params = shift;
            $USERS{ $params->{id} };
        };

        summary 'Delete user';
        del sub {
            my $params = shift;
            delete $USERS{ $params->{id} };
            res->status(HTTP_NO_CONTENT);
            undef;
        };
    };
};

run;
