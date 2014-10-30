#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib ("$Bin/../../../lib", "$Bin/../lib");

use Raisin::API;
use Raisin::Entity;

use Types::Standard qw(Any Int Str);

use MusicApp::Entity::Artist;
use MusicApp::Schema;

my $schema = MusicApp::Schema->connect("dbi:SQLite:$Bin/../db/music.db");

plugin 'Swagger', enable => 'CORS';
api_format 'yaml';

desc 'Artist API';
resource artists => sub {
    desc 'List';
    params optional => { name => 'name', type => Str };
    get sub {
        my $params = shift;
        my $artists = $schema->resultset('Artist');

        present data => $artists, with => 'MusicApp::Entity::Artist';
        present count => $artists->count;
    };
};

run;
