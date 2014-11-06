use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

package ArtistEntity;

use Scalar::Util 'blessed';
use parent 'Raisin::Entity';

__PACKAGE__->expose('id');
__PACKAGE__->expose('name', as => 'artist');
__PACKAGE__->expose('website', if => sub {
    my $artist = shift;
    blessed($artist) && $artist->can('website');
});
__PACKAGE__->expose('albums', using => 'AlbumEntity');
__PACKAGE__->expose('hash', sub {
    my $artist = shift;
    my $hash = 0;
    my $name = blessed($artist) ? $artist->name : $artist->{name};
    foreach (split //, $name) {
        $hash = $hash * 42 + ord($_);
    }
    $hash;
});

package AlbumEntity;

use parent 'Raisin::Entity';

__PACKAGE__->expose('title');
__PACKAGE__->expose('year');

package main;

my @STANDARD = (
    {
        id => 1,
        artist => 'Nirvana',
        albums => [
            {
                title => 'Bleach',
                year => 1989,
            },
            {
                title => 'Nevermind',
                year => 1991,
            },
            {
                title => 'In Utero',
                year => 1993,
            },
        ],
        hash => 442230706945,
    },
    {
        id => 2,
        artist => 'Green Day',
        albums => [
            {
                title => '39/Smooth',
                year => 1990,
            },
            {
                title => 'Kerplunk',
                year => 1992,
            },
            {
                title => 'Dookie',
                year => 1994,
            },
            {
                title => 'Insomniac',
                year => 1995,
            },
            {
                title => 'Nimrod',
                year => 1997,
            },
            {
                title => 'Warning',
                year => 2000,
            },
            {
                title => 'American Idiot',
                year => 2004,
            },
            {
                title => '21st Century Breakdown',
                year => 2009,
            }
        ],
        hash => 714317712537907,
    },
);

subtest 'compile native data' => sub {
     my %single = (
        id => 1,
        name => 'Nirvana',
        albums => [
            {
                id => 1,
                title => 'Bleach',
                year => 1989,
            },
            {
                id => 2,
                title => 'Nevermind',
                year => 1991,
            },
            {
                id => 3,
                title => 'In Utero',
                year => 1993,
            },
        ],
    );

   my @list = (
        \%single,
        {
            id => 2,
            name => 'Green Day',
            albums => [
                {
                    id => 4,
                    title => '39/Smooth',
                    year => 1990,
                },
                {
                    id => 5,
                    title => 'Kerplunk',
                    year => 1992,
                },
                {
                    id => 6,
                    title => 'Dookie',
                    year => 1994,
                },
                {
                    id => 7,
                    title => 'Insomniac',
                    year => 1995,
                },
                {
                    id => 8,
                    title => 'Nimrod',
                    year => 1997,
                },
                {
                    id => 9,
                    title => 'Warning',
                    year => 2000,
                },
                {
                    id => 10,
                    title => 'American Idiot',
                    year => 2004,
                },
                {
                    id => 10,
                    title => '21st Century Breakdown',
                    year => 2009,
                }
            ],
        },
    );

    subtest 'w/ entity' => sub {
        my $list_res = ArtistEntity->compile(\@list);
        is_deeply $list_res, \@STANDARD, 'list';

        my $single_res = ArtistEntity->compile(\%single);
        is_deeply $single_res, $STANDARD[0], 'single';
    };

    subtest 'w/o entity' => sub {
        my $list_res = Raisin::Entity->compile(\@list);
        is_deeply $list_res, \@list, 'list';

        my $single_res = Raisin::Entity->compile(\%single);
        is_deeply $single_res, \%single, 'single';
    };
};

subtest 'compile DBIx::Class' => sub {
    plan(skip_all => 'Requires test application');
    my $installed = eval {
        require DBIx::Class;
        DBIx::Class->import();
        1;
    };
    plan(skip_all => 'because DBIx::Class not installed.') if not $installed;

    my $schema = TestApp::Schema->connect("dbi:SQLite:$Bin/../testapp/db/music.db");

    subtest 'w/ entity' => sub {
        my $list_res = ArtistEntity->compile($schema->resultset('Artist'));
#        is_deeply $list_res, \@STANDARD, 'list';

        my $single_res = ArtistEntity->compile(
            $schema->resultset('Artist')->find(1)
        );
#        is_deeply $single_res, $STANDARD[0], 'single';
    };

    subtest 'w/o entity' => sub {
        my $list_res = Raisin::Entity->compile($schema->resultset('Artist'));
#        is_deeply $list_res, \@list, 'list';

        my $single_res = Raisin::Entity->compile(
            $schema->resultset('Artist')->find(1)
        );
#        is_deeply $single_res, \%single, 'single';
    };
};

subtest 'compile Rose::DB::Object' => sub {
    plan(skip_all => 'Requires test application');
    my $installed = eval {
        require DBIx::Class;
        DBIx::Class->import();
        1;
    };
    plan(skip_all => 'because Rose::DB::Object not installed.') if not $installed;

    subtest 'w/ entity' => sub {
        ok 0;
    };

    subtest 'w/o entity' => sub {
        ok 0;
    };
};

done_testing;
