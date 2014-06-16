#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use List::Util qw(max);

use lib "$FindBin::Bin/../../lib"; # ->Raisin/lib

use Raisin::API;
use Types::Standard qw(Any Str);

my $VERSION = 1;
my $NAME = 'Raisin';

my %VARIABLES = (
    name => {
        key => 'iamakey',
        data => 'somedata',
        extra => 'someextradata',
    },
);

namespace api => sub {
    get grape => sub { 'Grape!' };
    get raisin => sub {
        {
            version => $VERSION,
            name => $NAME,
            variables => \%VARIABLES,
        }
    };

    namespace sample => sub {
        get sub { \%VARIABLES };

        params [
            requires => ['name', Str],
            requires => ['key', Str],
            optional => ['data', Any],
            optional => ['extra', Any],
        ],
        post => sub {
            my $params = shift;
            $VARIABLES{ delete $params->{name} } = $params;
            { success => 1 }
        };

        route_param name => Str,
        sub {
            get sub {
                my $params = shift;
                { data => $VARIABLES{ $params->{name} } }
            };

            params [
                optional => ['data', Any],
                optional => ['extra', Any],
            ],
            put => sub {
                my $params = shift;
                $VARIABLES{ delete $params->{name} }{$_} = $params->{$_} for keys %$params;
                { success => 1 }
            };

            del sub {
                my $params = shift;
                delete $VARIABLES{ $params->{name} };
                { success => 1 }
            };
        };
    };
};

run;
