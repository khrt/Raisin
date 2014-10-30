#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

use DDP;
use FindBin '$Bin';

use lib "$Bin/../lib";

use MusicApp::Schema;
my $schema = MusicApp::Schema->connect("dbi:SQLite:$Bin/../db/music.db");

my $rs = $schema->resultset('Album');#->search({ artist => 'Nirvana' });

say keys %{ $rs->result_source->columns_info };
#p $rs->result_source->resultset;
p $rs->result_source->resultset_attributes;

while (my $album = $rs->next) {
    #say $album->artist . ' - ' . $album->title;
    say $album->artist->name . ' - ' . $album->title;
    #say $album->title;
}
