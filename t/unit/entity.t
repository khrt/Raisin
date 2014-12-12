
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib ("$Bin/../../lib", "$Bin/../app");

use Raisin::Entity;

my $CONDITION = sub { shift->{data} ? 1 : 0 };
my $NESTED = sub { expose 'id' };
my $RUNTIME = sub { shift->{data} };

my @CASES = (
    {
        params => ['basic'],
        input => { basic => 'abcd-basic', },
        expected => {
            compile => { basic => 'abcd-basic', },
            exposition => [{ name => 'basic' }],
            expose => {
                alias => undef,
                condition => undef,
                name => 'basic',
                runtime => undef,
                using => undef,
            },
        },
    },
    {
        params => ['presenter', using => 'Raisin::Entity'],
        input => { data => 'set', presenter => { id => 1, name => 'use', } },
        expected => {
            compile => { presenter => { id => 1, name => 'use', } },
            exposition => [{ name => 'data' }, { name => 'presenter' }],
            expose => {
                alias => undef,
                condition => undef,
                name => 'presenter',
                runtime => undef,
                using => 'Raisin::Entity',
            },
        },
    },
    {
        params => ['condition', if => $CONDITION],
        input => { condition => 'set', data => 1 },
        expected => {
            compile => { condition => 'set' },
            exposition => [{ name => 'condition' }, { name => 'data' }],
            expose => {
                alias => undef,
                condition => $CONDITION,
                name => 'condition',
                runtime => undef,
                using => undef,
            },
        },
    },
    {
        params => ['nested', $NESTED],
        input => { id => 'abcd' },
        expected => {
            compile => { nested => { id => 'abcd' } },
            exposition => [{ name => 'id' }],
            expose => {
                alias => undef,
                condition => undef,
                name => 'nested',
                runtime => $NESTED,
                using => undef,
            },
        },
    },
    {
        params => ['runtime', $RUNTIME],
        input => { data => 'abcd', },
        expected => {
            compile => { runtime => 'abcd' },
            exposition => [{ name => 'data' }],
            expose => {
                alias => undef,
                condition => undef,
                name => 'runtime',
                runtime => $RUNTIME,
                using => undef,
            },
        },
    },
    {
        params => ['alias', as => 'i-am-an-alias'],
        input => { alias => 'aliased-data', },
        expected => {
            compile => { 'i-am-an-alias' => 'aliased-data', },
            exposition => [{ name => 'alias' }],
            expose => {
                alias => 'i-am-an-alias',
                condition => undef,
                name => 'alias',
                runtime => undef,
                using => undef,
            },
        },
    },
    # TODO: documentation
    #{
    #    params => ['documentation', documentation => { ... }],
    #    input => {},
    #    expected => {
    #        compile => {},
    #        exposition => [{ name => '' }],
    #        expose => {
    #            alias => undef,
    #            condition => undef,
    #            name => 'documentation',
    #            runtime => undef,
    #            using => undef,
    #        },
    #},
);

ok scalar(main->can('expose')), 'can expose';

subtest 'expose' => sub {
    for my $case (@CASES) {
        subtest $case->{params}[0] => sub {
            # XXX:
            expose @{ $case->{params} };

            my @expose = do {
                no strict 'refs';
                @{'main::EXPOSE'}
            };

            is scalar @expose, 1, 'length';
            is_deeply $expose[0], $case->{expected}{expose}, 'compare';

            if ($case->{params}[0] =~ /nested/) {
                my $compile_res = Raisin::Entity->compile('main',
                    $case->{input}, \@expose);

                is_deeply $compile_res, $case->{expected}{compile}, 'nested: compile';
            }

            if ($case->{params}[0] =~ /runtime/) {
                is_deeply $expose[0]->{runtime}->($case->{input}),
                $RUNTIME->($case->{input}), 'runtime: exec';
            }

            delete $main::{EXPOSE};
        };
    }

    {
        no strict 'refs';
        is_deeply \@{'main::EXPOSE'}, [], 'EXPOSE is empty';
    }
};

subtest 'compile' => sub {
    subtest 'Perl data structures' => sub {
        for my $case (@CASES) {
            subtest $case->{params}[0] => sub {
                # XXX:
                expose @{ $case->{params} };

                my @expose = do {
                    no strict 'refs';
                    @{'main::EXPOSE'}
                };

                my $we = Raisin::Entity->compile('main', $case->{input});
                is_deeply $we, $case->{expected}{compile}, 'w/ entity';

                delete $main::{EXPOSE};

                my $woe = Raisin::Entity->compile('main', $case->{input});
                is_deeply $woe, $case->{input}, 'w/o entity';

            };
        }
    };

    subtest 'DBIx::Class' => sub {
        plan skip_all => 'NA';
    };

    subtest 'Rose::DB::Object' => sub {
        plan skip_all => 'NA';
    };

    {
        no strict 'refs';
        is_deeply \@{'main::EXPOSE'}, [], 'EXPOSE is empty';
    }
};

subtest '_compile_column' => sub {
    subtest 'HASH' => sub {
        for my $case (@CASES) {
            expose @{ $case->{params} };

            my @expose = do {
                no strict 'refs';
                @{'main::EXPOSE'}
            };

            my $res = Raisin::Entity::_compile_column('main',
                $case->{input}, \@expose);
            is_deeply $res, $case->{expected}{compile}, $case->{params}[0];

            delete $main::{EXPOSE};
        }
    };

    subtest 'blessed' => sub {
        plan skip_all => 'NA';
    };

    {
        no strict 'refs';
        is_deeply \@{'main::EXPOSE'}, [], 'EXPOSE is empty';
    }
};

subtest '_make_exposition' => sub {
    subtest 'Perl data structures' => sub {
        for my $case (@CASES) {
            my @expose = Raisin::Entity::_make_exposition($case->{input});
            @expose = sort { $a->{name} cmp $b->{name} } @expose;
            my @expected = sort { $a->{name} cmp $b->{name} } @{ $case->{expected}{exposition} };

            is_deeply \@expose, \@expected, $case->{params}[0];
        }
    };

    subtest 'DBIx::Class' => sub {
        plan skip_all => 'NA';
    };

    subtest 'Rose::DB::Object' => sub {
        plan skip_all => 'NA';
    };
};

done_testing;

__END__
my @STANDARD = (
    {
        id => 1,
        artist => 'Nirvana',
        albums => [
            { title => 'Bleach', year => 1989, },
            { title => 'Nevermind', year => 1991, },
            #{ title => 'In Utero', year => 1993, },
        ],
        hash => 442230706945,
    },
    {
        id => 2,
        artist => 'Green Day',
        albums => [
            { title => '39/Smooth', year => 1990, },
            { title => 'Kerplunk', year => 1992, },
            #{ title => 'Dookie', year => 1994, },
            #{ title => 'Insomniac', year => 1995, },
            #{ title => 'Nimrod', year => 1997, },
            #{ title => 'Warning', year => 2000, },
            #{ title => 'American Idiot', year => 2004, },
            #{ title => '21st Century Breakdown', year => 2009, }
        ],
        hash => 714317712537907,
    },
);

    #use TApp::Entity::Album;
    #use TApp::Entity::Artist;

    #expose 'id';
    #expose 'services', using => 'Entity::Service';
    #expose 'website', if => sub { shift->can('website') };
    #expose 'contacts', sub {
    #    expose 'address';
    #    expose 'city';
    #    expose 'country';
    #    expose 'postcode';
    #};
    #expose 'rand', sub { rand };
    #expose 'name', as => 'fullname';
    #expose 'last_logged', documentation => { type => 'String', desc => 'Last logged' };

#subtest 'compile native data' => sub {
#    my @list = (
#        {
#            id => 1,
#            name => 'Nirvana',
#            albums => [
#                { id => 1, title => 'Bleach', year => 1989, },
#                { id => 2, title => 'Nevermind', year => 1991, },
#                #{ id => 3, title => 'In Utero', year => 1993, },
#            ],
#        },
#        {
#            id => 2,
#            name => 'Green Day',
#            albums => [
#                { id => 4, title => '39/Smooth', year => 1990, },
#                { id => 5, title => 'Kerplunk', year => 1992, },
#                #{ id => 6, title => 'Dookie', year => 1994, },
#                #{ id => 7, title => 'Insomniac', year => 1995, },
#                #{ id => 8, title => 'Nimrod', year => 1997, },
#                #{ id => 9, title => 'Warning', year => 2000, },
#                #{ id => 10, title => 'American Idiot', year => 2004, },
#                #{ id => 10, title => '21st Century Breakdown', year => 2009, }
#            ],
#        },
#    );
#    my %single = %{ $list[0] };
#
#    use Raisin::Entity;
#    require TApp::Entity::Album;
#
#    my $res;
#    $res = Raisin::Entity->compile('TApp::Entity::Album', $single{albums});
#    note explain $res;
#
#    $res = Raisin::Entity->compile('TApp::Entity::Album', $single{albums});
#    note explain $res;
#    ok 1;
#};

    #my $res = TApp::Entity::Artist->compile(\%single);
    #note explain $res;

#    subtest 'w/ entity' => sub {
#        my $list_res = TApp::Entity::Artist->compile(\@list);
#        note explain $list_res;
#        BAIL_OUT 'no reason';
#        is_deeply $list_res, \@STANDARD, 'list';
#
#        my $single_res = TApp::Entity::Artist->compile(\%single);
#        is_deeply $single_res, $STANDARD[0], 'single';
#    };
#
#    subtest 'w/o entity' => sub {
#        my $list_res = Raisin::Entity->compile(\@list);
#        is_deeply $list_res, \@list, 'list';
#
#        my $single_res = Raisin::Entity->compile(\%single);
#        is_deeply $single_res, \%single, 'single';
#    };
##};

#subtest 'compile DBIx::Class' => sub {
#    plan(skip_all => 'Requires test application');
#    my $installed = eval {
#        require DBIx::Class;
#        DBIx::Class->import();
#        1;
#    };
#    plan(skip_all => 'because DBIx::Class not installed.') if not $installed;
#
#    my $schema = TestApp::Schema->connect("dbi:SQLite:$Bin/../testapp/db/music.db");
#
#    subtest 'w/ entity' => sub {
#        my $list_res = ArtistEntity->compile($schema->resultset('Artist'));
##        is_deeply $list_res, \@STANDARD, 'list';
#
#        my $single_res = ArtistEntity->compile(
#            $schema->resultset('Artist')->find(1)
#        );
##        is_deeply $single_res, $STANDARD[0], 'single';
#    };
#
#    subtest 'w/o entity' => sub {
#        my $list_res = Raisin::Entity->compile($schema->resultset('Artist'));
##        is_deeply $list_res, \@list, 'list';
#
#        my $single_res = Raisin::Entity->compile(
#            $schema->resultset('Artist')->find(1)
#        );
##        is_deeply $single_res, \%single, 'single';
#    };
#};
