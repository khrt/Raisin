package MusicApp::Entity::Artist;

use strict;
use warnings;

use parent 'Raisin::Entity';

__PACKAGE__->expose('id');
__PACKAGE__->expose('name', if => sub { shift->name eq 'Nirvana' });
__PACKAGE__->expose('name', as => 'artist');
__PACKAGE__->expose('hash', sub {
    my $item = shift;
    $item->id * 10;
});
__PACKAGE__->expose('albums', using => 'MusicApp::Entity::Album');

1;
