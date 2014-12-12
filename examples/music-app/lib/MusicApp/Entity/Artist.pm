package MusicApp::Entity::Artist;

use strict;
use warnings;

use Raisin::Entity;

expose 'id';
expose 'name', if => sub { shift->name eq 'Nirvana' };
expose 'name', as => 'artist';
expose 'hash', sub {
    my $item = shift;
    $item->id * 10;
};
expose 'albums', using => 'MusicApp::Entity::Album';

1;
