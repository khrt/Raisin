package MusicApp::RDBO::Album;

use strict;
use warnings;

use MusicApp::RDBO;
use parent 'Rose::DB::Object';

__PACKAGE__->meta->setup(
    table => 'albums',
    columns => [qw(id artist_id title year)],
    pk_columns => 'id',
    relationships => [
        artist => {
            type => 'many to one',
            class => 'MusicApp::RDBO::Artist',
            column_map => { artist_id => 'id' },
        },
    ],
);

Rose::DB::Object::Manager->make_manager_methods('albums');

1;
