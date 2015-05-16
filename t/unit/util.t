
use strict;
use warnings;

use Test::More;

use Raisin::Util;

my @CASES = (
    { input => 'application/json-rpc', expected => 'json' },
    { input => 'application/json', expected => 'json' },
    { input => 'json', expected => 'json' },

    { input => 'application/yaml', expected => 'yaml' },
    { input => 'application/yml', expected => 'yaml' },
    { input => 'yaml', expected => 'yaml' },
    { input => 'yml', expected => 'yaml' },

    { input => 'text/*', expected => 'text' },
    { input => 'text/html', expected => undef },
    { input => 'text/plain', expected => 'text' },
    { input => 'text', expected => 'text' },
    { input => 'txt', expected => 'text' },

    { input => 'application/xml', expected => undef },
);

subtest 'detect_serializer' => sub {
    for my $case (@CASES) {
        my $title = 'Detect: ' . ($case->{expected} || '*');
        is Raisin::Util::detect_serializer($case->{input}), $case->{expected}, $title;
    }
};

done_testing;
