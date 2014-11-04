package MusicApp::RDBO::Artist;

use strict;
use warnings;

use MusicApp::RDBO;
use parent 'Rose::DB::Object';

__PACKAGE__->meta->setup(
    table => 'artists',
    columns => [qw(id name)],
    pk_columns => 'id',
    relationships => [
        albums => {
            type => 'one to many',
            class => 'MusicApp::RDBO::Album',
            column_map => { id => 'artist_id' },
        },
    ],
);

Rose::DB::Object::Manager->make_manager_methods('artists');

1;
