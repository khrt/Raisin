
use strict;
use warnings;

use Test::More;
use Raisin::Param;

BEGIN {
    unless (eval { require MooseX::Types::Moose; 1; }) {
        plan skip_all => 'This test requires MooseX::Types';
    }

    MooseX::Types::Moose->import('Str');
}

{
    no strict 'refs';
    *Raisin::log = sub { note(sprintf $_[1], @_[2 .. $#_]) };
}

my $QUIET = 1;

my $param = Raisin::Param->new(
    named => int(rand(1)),
    type  => 'required',
    spec  => { name => 'Str', type => Str, default => 'def' }
);

isa_ok $param, 'Raisin::Param';

my $test = 'Hello world';
is $param->validate(\$test, $QUIET&0), '1';

done_testing;
