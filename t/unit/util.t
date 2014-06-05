
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Util;

subtest 'detect_serializer' => sub {
    is Raisin::Util::detect_serializer('application/json'), 'json', 'JSON content type';
    is Raisin::Util::detect_serializer('application/json-rpc'), 'json', 'JSON RPC content type';
    is Raisin::Util::detect_serializer('json'), 'json', 'JSON extension';

    is Raisin::Util::detect_serializer('application/yaml'), 'yaml', 'YAML content type';
    is Raisin::Util::detect_serializer('application/yml'), 'yaml', 'YAML content type';
    is Raisin::Util::detect_serializer('yaml'), 'yaml', 'YAML extension';
    is Raisin::Util::detect_serializer('yml'), 'yaml', 'YAML extension';
};

done_testing;
