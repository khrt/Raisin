package MusicApp::Schema::Result::Album;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table('albums');
__PACKAGE__->add_columns(qw/id artist_id title year/);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to('artist', 'MusicApp::Schema::Result::Artist', 'artist_id');

1;
