package MusicApp::Entity::Album;

use strict;
use warnings;

use Types::Standard qw/Int Str/;
use Raisin::Entity;

expose 'id',    type => Int, desc => 'ID';
expose 'title', type => Str, desc => 'Title';
expose 'year',  type => Int, desc => 'Year';

1;
