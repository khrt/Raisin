
use strict;
use warnings;

use Test::More;
use Raisin::Param;

BEGIN {
    unless (eval { require Moose; 1; }) {
        plan skip_all => 'This test requires Moose';
    }

    unless (eval { require MooseX::Types::Moose; 1; }) {
        plan skip_all => 'This test requires MooseX::Types';
    }

    MooseX::Types::Moose->import('Str');
    MooseX::Types->import( -declare => [ qw( Foo ) ] );
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

# Test moose coercion

# Create an anonymous class
my $meta = Moose::Meta::Class->create_anon_class;
$meta->add_attribute(foo => (is => 'ro', isa => 'Str', required => 1));

subtype Foo,
   as class_type($meta->name);

# create a coercion for the class
coerce Foo,
    from Str,
    via { $meta->new_object( foo => $_ ) };

$param = Raisin::Param->new(
    named => int(rand(1)),
    type  => 'required',
    spec  => { name => 'foo', type => Foo }
);

isa_ok $param, 'Raisin::Param';

$test = 'Hello World';
is $param->validate(\$test, $QUIET&0), '1';
isa_ok $test, $meta->name;
is $test->foo, 'Hello World';

done_testing;
