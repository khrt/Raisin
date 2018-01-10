#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Raisin::API;
use Raisin::Entity;

use Types::Standard qw(Any Int Str);

use MusicApp::Entity::Artist;
use MusicApp::Entity::Album;

use MusicApp::Schema;

my $schema = MusicApp::Schema->connect("dbi:SQLite:$Bin/../db/music.db");

plugin 'Swagger';
middleware 'CrossOrigin',
    origins => '*',
    methods => [qw/DELETE GET HEAD OPTIONS PATCH POST PUT/],
    headers => [qw/accept authorization content-type api_key_token/];

api_default_format 'yaml';

desc 'Artist API';
resource artists => sub {
    summary 'List';
    entity 'MusicApp::Entity::Artist';
    get sub {
        my $params = shift;
        my $artists = $schema->resultset('Artist');

        present data => $artists, with => 'MusicApp::Entity::Artist';
        present count => $artists->count;
    };

    params requires('id', type => Int);
    entity 'MusicApp::Entity::Artist';
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
    summary 'List';
    get sub {
        my $params = shift;
        my $albums = $schema->resultset('Album');

        present data => $albums;
        present count => $albums->count;
    };

    params requires('id', type => Int);
    route_param id => sub {
        get sub {
            my $params = shift;
            my $album = $schema->resultset('Album')->find($params->{id});

            present data => $album;
        };
    };
};

run;
