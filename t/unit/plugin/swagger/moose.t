use strict;
use warnings;

use Test::More;

use Raisin;
use Raisin::Param;
use Raisin::Plugin::Swagger;

BEGIN {
    unless (eval { require Moose::Util::TypeConstraints; 1 }) {
        plan skip_all => 'This test requires Moose::Util::TypeConstraints';
    }

    Moose::Util::TypeConstraints->import('enum');
}

my @PARAMETERS_CASES = (
    {
        method => 'POST',
        params => [
            Raisin::Param->new(
                named => 0,
                type  => 'required',
                spec  => { name => 'enum', type => enum([qw(foo bar)]), default => 'foo', in => 'body' },
            )
        ],
        expected => [
            {
                default     => 'foo',
                description => '',
                in          => 'body',
                name        => 'enum',
                required    => JSON::MaybeXS::true,
                type        => 'string',
                enum        => [ qw( foo bar ) ],
            }
        ]
    },
);

for my $case (@PARAMETERS_CASES) {
    my $obj = Raisin::Plugin::Swagger::_parameters_object(
        $case->{method},
        $case->{params}
    );

    is_deeply $obj, $case->{expected},
        "$case->{method} $case->{expected}[0]{in} $case->{expected}[0]{name}";
}

done_testing;
