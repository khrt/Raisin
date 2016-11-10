
use strict;
use warnings;

use Test::More;
use Types::Standard qw/Any ArrayRef HashRef Int/;

use Raisin::Entity::Object;

my @CASES = (
    {
        def => { 'id' => { type => Int, desc => 'ID', as => 'ref', }, },
        expected => { name => 'id', alias => 'ref', type => Int },
    },
    {
        def => { 'name' => { type => Int, desc => 'Name', } },
        expected =>  { name => 'name', alias => undef, type => Int },
    },
    {
        def => { 'link_expl' => { type => Int, desc => 'Name', using => 'SomeOther::Entity' } },
        expected => { name => 'link', type => Int },
    },
    {
        def => { 'link' => { desc => 'Name', using => 'SomeOther::Entity' } },
        expected => { name => 'link', type => ArrayRef[HashRef] },
    },
    {
        def => { 'any' => { desc => 'Name' } },
        expected => { name => 'link', type => Any },
    },
);

subtest 'alias' => sub {
    for my $c (@CASES) {
        my ($name, $def) = %{ $c->{def} };

        my $o = Raisin::Entity::Object->new($name, %$def);
        is $o->alias, $def->{as}, $name;
    }
};

subtest 'condition' => sub {
    plan skip_all => 'NA';
};

subtest 'type' => sub {
    for my $c (@CASES) {
        my ($name, $def) = %{ $c->{def} };

        my $o = Raisin::Entity::Object->new($name, %$def);
        is $o->type->display_name, $c->{expected}{type}->display_name, $name;
    }
};

subtest 'display_name' => sub {
    for my $c (@CASES) {
        my ($name, $def) = %{ $c->{def} };

        my $o = Raisin::Entity::Object->new($name, %$def);
        is $o->display_name, ($def->{as} || $name), $name;
    }
};

done_testing;
