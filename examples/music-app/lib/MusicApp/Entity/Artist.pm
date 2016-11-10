package MusicApp::Entity::Artist;

use strict;
use warnings;

use Types::Standard qw/Int Str/;
use Raisin::Entity;

expose 'id',   type => Int, desc => 'ID';
expose 'name', type => Str, desc => 'Artist name /shown only if it equals to Nirvana/', if => sub { shift->name eq 'Nirvana' };
expose 'name', type => Str, desc => 'Artist name', as => 'artist';
expose 'hash', type => Str, desc => 'ID*10', sub {
    my $item = shift;
    $item->id * 10;
};
expose 'albums', desc => 'Artist\'s albums', using => 'MusicApp::Entity::Album';

1;
