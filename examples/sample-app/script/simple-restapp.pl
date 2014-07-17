#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib ("$Bin/../lib", "$Bin/../../../lib");

use List::Util qw(max);
use Plack::Builder;

use Raisin::API;
use Types::Standard qw(Int Str);

use UseCase::Host;
use UseCase::User;

# Utils
sub paginate {
    my ($data, $params) = @_;

    my $max_count = scalar(@$data) - 1;
    my $start = _return_max($params->{start}, $max_count);
    my $count = _return_max($params->{count}, $max_count);

    my @slice = @$data[$start .. $count];
    \@slice;
}

sub _return_max {
    my ($value, $max) = @_;
    $value > $max ? $max : $value;
}

plugin 'APIDocs', enable => 'CORS';
plugin 'Logger', outputs => [['Screen', min_level => 'debug']];

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

resource host => sub {
    params [
        optional => { name => 'start', type => Int, default => 0, desc => 'Pager start' },
        optional => { name => 'count', type => Int, default => 10, desc => 'Pager count' },
    ],
    desc => 'List hosts',
    get => sub {
        my $params = shift;
        my @hosts = UseCase::Host::list(%$params);
        { data => paginate(\@hosts, $params) }
    };

    params [
        required => { name => 'name', type => Str, desc => 'Host name' },
        required => { name => 'user_id', type => Int, desc => 'Host owner' },
        optional => { name => 'state', type => Str, desc => 'Host state' }
    ],
    desc => 'Create new host',
    post => sub {
        my $params = shift;
        { success => UseCase::Host::create(%$params) }
    };

    route_param id => Int,
    sub {
        desc 'Show host',
        get => sub {
            my $params = shift;
            { data => UseCase::Host::show($params->{id}) }
        };

        params [
            required => { name => 'state', type => Str, desc => 'Host state' },
        ],
        desc => 'Edit host',
        put => sub {
            my $params = shift;
            { data => UseCase::Host::edit($params->{id}, %$params) }
        };

        desc 'Delete host',
        del => sub {
            my $params = shift;
            { success => UseCase::Host::delete($params->{id}) }
        }
    };
};

builder { Plack::Builder::mount '/api' => run };
