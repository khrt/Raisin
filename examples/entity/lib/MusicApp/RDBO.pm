package MusicApp::RDBO;

use strict;
use warnings;

use parent 'Rose::DB';

use Rose::DB::Object::Metadata::Relationship::OneToMany;
use Rose::DB::Object::Metadata::Relationship::ManyToOne;

use FindBin '$Bin';

__PACKAGE__->use_private_registry;

Rose::DB->register_db(
    domain   => 'default',
    type     => 'default',
    driver   => 'sqlite',
    database => "$Bin/../db/music.db",
);

1;
