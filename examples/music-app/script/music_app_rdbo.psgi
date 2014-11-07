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

use MusicApp::RDBO::Artist;
use MusicApp::RDBO::Album;

plugin 'Swagger', enable => 'CORS';
api_default_format 'yaml';

desc 'Artist API';
resource artists => sub {
    desc 'List';
    get sub {
        my $params = shift;
        my $artists = MusicApp::RDBO::Artist->get_artists;

        present data => $artists, with => 'MusicApp::Entity::Artist';
        present count => scalar @$artists;
    };

    params requires => { name => 'id', type => Int };
    route_param id => sub {
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
    desc 'List';
    get sub {
        my $params = shift;
        my $albums = MusicApp::RDBO::Album->get_albums;

        present data => $albums;
        present count => scalar @$albums;
    };

    params requires => { name => 'id', type => Int };
    route_param id => sub {
        get sub {
            my $params = shift;
            my $album = MusicApp::RDBO::Album->new(id => $params->{id});
            $album->load;

            present data => $album;
        };
    };
};

run;
