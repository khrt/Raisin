
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Types;

subtest 'int' => sub {
    my $value = 1;

    my $int = Raisin::Types::Integer->new(\$value);
    is ref $int, 'Raisin::Types::Integer', 'valid';

    $int = Raisin::Types::Integer->new(\1.23);
    is $int, undef, 'invalid';
};

subtest 'float' => sub {
    my $value = 1.23;

    my $float = Raisin::Types::Float->new(\$value);
    is ref $float, 'Raisin::Types::Float', 'valid';

    $float = Raisin::Types::Float->new(\'string');
    is $float, undef, 'invalid';
};

subtest 'string' => sub {
    my $value = 'string';

    my $string = Raisin::Types::String->new(\$value);
    is ref $string, 'Raisin::Types::String', 'valid';
};

subtest 'scalar' => sub {
    my $value = 'scalar';

    my $scalar = Raisin::Types::Scalar->new(\$value);
    is ref $scalar, 'Raisin::Types::Scalar', 'valid';
};

done_testing;
