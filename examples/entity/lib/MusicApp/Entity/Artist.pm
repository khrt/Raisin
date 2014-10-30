package MusicApp::Entity::Artist;

use strict;
use warnings;

use parent 'Raisin::Entity';

__PACKAGE__->expose('id');
__PACKAGE__->expose('name');


    # expose :digest, sub {
    #   my $item = shift;
    #   hexhash($item->name);
    # }
_PACKAGE__->expose('hash', sub {
    my $item = shift;
    $item->id * 10;
});

1;
