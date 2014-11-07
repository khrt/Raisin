package MusicApp::Entity::Album;

use strict;
use warnings;

use parent 'Raisin::Entity';

__PACKAGE__->expose('id');
__PACKAGE__->expose('title');
__PACKAGE__->expose('year');

1;
