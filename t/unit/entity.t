
use strict;
use warnings;

use Test::More;

use Raisin::Entity;

my $CONDITION = sub { shift->{data} ? 1 : 0 };
my $NESTED = sub { expose 'id' };
my $RUNTIME = sub { shift->{data} };

my @CASES = (
    {
        params => ['basic_array'],
        input => { basic_array => [qw(a b c d)], },
        expected => {
            compile => { basic_array => [qw(a b c d)], },
            exposition => [],
            expose => {
                alias => undef,
                condition => undef,
                name => 'basic_array',
                runtime => undef,
                using => undef,
            },
        },
    },
    {
        params => ['basic_hash'],
        input => { basic_hash => { key0 => 'value0', key1 => 'value1' }, },
        expected => {
            compile => { basic_hash => { key0 => 'value0', key1 => 'value1' }, },
            exposition => [],
            expose => {
                alias => undef,
                condition => undef,
                name => 'basic_hash',
                runtime => undef,
                using => undef,
            },
        },
    },
    {
        params => ['basic_array_of_hashes'],
        input => { basic_array_of_hashes => [{ key0 => 'value0' }, { key1 => 'value1' }], },
        expected => {
            compile => { basic_array_of_hashes => [{ key0 => 'value0' }, { key1 => 'value1' }], },
            exposition => [],
            expose => {
                alias => undef,
                condition => undef,
                name => 'basic_array_of_hashes',
                runtime => undef,
                using => undef,
            },
        },
    },

    {
        params => ['basic'],
        input => { basic => 'abcd-basic', },
        expected => {
            compile => { basic => 'abcd-basic', },
            exposition => [],#[{ name => 'basic' }],
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
            exposition => [],#[{ name => 'data' }, { name => 'presenter' }],
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
            exposition => [],#[{ name => 'condition' }, { name => 'data' }],
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
            exposition => [],#[{ name => 'id' }],
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
            exposition => [],#[{ name => 'data' }],
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
            exposition => [],#[{ name => 'alias' }],
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
    #        exposition => [],#[{ name =>  }],
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
