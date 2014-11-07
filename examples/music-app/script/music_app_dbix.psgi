#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib ("$Bin/../../../lib", "$Bin/../lib");

use Raisin::API;
use Raisin::Entity;

use Types::Standard qw(Any Int Str);

use MusicApp::Entity::Artist;
use MusicApp::Entity::Album;

use MusicApp::Schema;

my $schema = MusicApp::Schema->connect("dbi:SQLite:$Bin/../db/music.db");

plugin 'Swagger', enable => 'CORS';
api_default_format 'yaml';

desc 'Artist API';
resource artists => sub {
    desc 'List';
    get sub {
        my $params = shift;
        my $artists = $schema->resultset('Artist');

        present data => $artists, with => 'MusicApp::Entity::Artist';
        present count => $artists->count;
    };

    params requires => { name => 'id', type => Int };
    route_param id => sub {
        get sub {
            my $params = shift;
            my $artist = $schema->resultset('Artist')->find($params->{id});

            present data => $artist, with => 'MusicApp::Entity::Artist';
        };
    };
};

desc 'Albums API';
resource albums => sub {
    desc 'List';
    get sub {
        my $params = shift;
        my $albums = $schema->resultset('Album');

        present data => $albums;
        present count => $albums->count;
    };

    params requires => { name => 'id', type => Int };
    route_param id => sub {
        get sub {
            my $params = shift;
            my $album = $schema->resultset('Album')->find($params->{id});

            present data => $album;
        };
    };
};

run;
