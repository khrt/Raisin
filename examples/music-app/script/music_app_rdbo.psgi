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

use MusicApp::RDBO::Artist;
use MusicApp::RDBO::Album;

plugin 'Swagger';
middleware 'CrossOrigin',
    origins => '*',
    methods => [qw/DELETE GET HEAD OPTIONS PATCH POST PUT/],
    headers => [qw/accept authorization content-type api_key_token/];

api_default_format 'yaml';

desc 'Artist API';
resource artists => sub {
    summary 'Returns all artists';
    entity 'MusicApp::Entity::Artist';
    get sub {
        my $params = shift;
        my $artists = MusicApp::RDBO::Artist->get_artists;

        present data => $artists, with => 'MusicApp::Entity::Artist';
        present count => scalar @$artists;
    };

    params requires('id', type => Int);
    route_param id => sub {
        summary 'Returns an artist';
        entity 'MusicApp::Entity::Artist';
        get sub {
            my $params = shift;
            my $artist = MusicApp::RDBO::Artist->new(id => $params->{id});
            $artist->load;

            present data => $artist, with => 'MusicApp::Entity::Artist';
        };
    };
};

desc 'Albums API';
resource albums => sub {
    summary 'Returns all albums';
    entity 'MusicApp::Entity::Album';
    get sub {
        my $params = shift;
        my $albums = MusicApp::RDBO::Album->get_albums;

        present data => $albums;
        present count => scalar @$albums;
    };

    params requires('id', type => Int);
    route_param id => sub {
        summary 'Returns an album';
        entity 'MusicApp::Entity::Album';
        get sub {
            my $params = shift;
            my $album = MusicApp::RDBO::Album->new(id => $params->{id});
            $album->load;

            present data => $album;
        };
    };
};

run;
