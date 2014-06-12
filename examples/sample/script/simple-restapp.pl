#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib ("$Bin/../lib", "$Bin/../../../lib");

use List::Util qw(max);

use Raisin::API;
use Raisin::Types;

use RESTApp;
use UseCase::Host;
use UseCase::User;

plugin 'APIDocs';
plugin 'Logger', outputs => [['Screen', min_level => 'debug']];
api_format 'yaml';

namespace api => sub {
    namespace user => sub {
        params [
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
};

run;
