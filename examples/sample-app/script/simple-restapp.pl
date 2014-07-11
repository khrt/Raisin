#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib ("$Bin/../lib", "$Bin/../../../lib");

use List::Util qw(max);

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

plugin 'APIDocs';
plugin 'Logger', outputs => [['Screen', min_level => 'debug']];
api_format 'yaml';

resource api => sub {
    resource user => sub {
        params [
            optional => ['start', Int, 0, qr/^\d+$/],
            optional => ['count', Int, 10, qr/^\d+$/],
        ],
        get => sub {
            my $params = shift;
            my @users = UseCase::User::list(%$params);
            { data => paginate(\@users, $params) }
        };

        get 'all' => sub {
            my $params = shift;
            my @users = UseCase::User::list(%$params);
            { data => \@users }
        };

        params [
            required => ['name', Str],
            required => ['password', Str],
            optional => ['email', Str, undef],
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
                optional => ['email', Str],
            ],
            put => sub {
                my $params = shift;
                { data => UseCase::User::edit($params->{id}, %$params) }
            };

            resource bump => sub {
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

    resource host => sub {
        params [
            optional => ['start', Int, 0, qr/^\d+$/],
            optional => ['count', Int, 10, qr/^\d+$/],
        ],
        get => sub {
            my $params = shift;
            my @hosts = UseCase::Host::list(%$params);
            { data => paginate(\@hosts, $params) }
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
                { data => UseCase::Host::edit($params->{id}, %$params) }
            };

            del sub {
                my $params = shift;
                { success => UseCase::Host::delete($params->{id}) }
            }
        };
    };
};

run;
