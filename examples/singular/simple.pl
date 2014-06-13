#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use List::Util qw(max);

use lib "$FindBin::Bin/../../lib"; # ->Raisin/lib

use Raisin::API;
use Raisin::Types;

my $VERSION = 1;
my $NAME = 'Raisin';
my %VARIABLES = {};

namespace api => sub {
    get grape => sub { 'Grape!' };

    namespace raisin => sub {
        get sub {
            {
                version => $VERSION,
                name => $NAME,
                variables => \%VARIABLES,
            }
        };

        params [
            requires => ['name', 'Raisin::Types::String'],
            requires => ['key', 'Raisin::Types::String'],
            optional => ['data', 'Raisin::Types::Scalar'],
            optional => ['extra', 'Raisin::Types::Scalar'],
        ],
        post => sub {
            my $params = shift;
            $VARIABLES{ delete $params->{name} } = $params;
            { success => 1 }
        };

        route_param name => 'Raisin::Types::String',
        sub {
            params [
                optional => ['data', 'Raisin::Types::Scalar'],
                optional => ['extra', 'Raisin::Types::Scalar'],
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
