
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Types;

subtest 'Bool' => sub {
    my $bool = $Raisin::Types::Bool->(1);
    is $bool, 1, 'true';

    $bool = $Raisin::Types::Bool->(0);
    is $bool, 0, 'false';

    my $e;
    eval { $Raisin::Types::Bool->(2) } || do { $e = $@ };
    like $e, qr/did not pass type constraint/, 'invalid';
};

subtest 'Integer' => sub {
    my $Int = $Raisin::Types::Integer->(1);
    is $Int, 1, 'valid';

    my $e;
    eval { $Raisin::Types::Integer->(1.23) } || do { $e = $@ };
    like $e, qr/did not pass type constraint/, 'invalid';
};

subtest 'Numeric' => sub {
    my $Numeric = $Raisin::Types::Numeric->(1);
    is $Numeric, 1, 'integer';

    $Numeric = $Raisin::Types::Numeric->(1.23);
    is $Numeric, 1.23, 'float';

    my $e;
    eval { $Raisin::Types::Numeric->('string') } || do { $e = $@ };
    like $e, qr/did not pass type constraint/, 'invalid';
};

subtest 'String' => sub {
    my $String = $Raisin::Types::String->('string');
    is $String, 'string', 'true';
};

done_testing;
