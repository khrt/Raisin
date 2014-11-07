package MusicApp::Schema::Result::Artist;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table('artists');
__PACKAGE__->add_columns(qw/id name/);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many('albums', 'MusicApp::Schema::Result::Album', 'artist_id');

1;
