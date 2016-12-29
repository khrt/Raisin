
use strict;
use warnings;

use Test::More;

use Raisin::Util;

subtest 'make_tag_from_path' => sub {
    is Raisin::Util::make_tag_from_path('/tank/dev/web'), 'dev';
    is Raisin::Util::make_tag_from_path('/str'), 'str';
    is Raisin::Util::make_tag_from_path('/'), undef;
};

subtest 'iterate_params' => sub {
    my $i = Raisin::Util::iterate_params([qw/key0 val0 key1 val1 key2 val2/]);
    is_deeply [$i->()], [qw/key0 val0/];
    is_deeply [$i->()], [qw/key1 val1/];
    is_deeply [$i->()], [qw/key2 val2/];
    is_deeply [$i->()], [undef, undef];
};

done_testing;
