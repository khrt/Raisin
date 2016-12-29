
use strict;
use warnings;

use Test::More;
use Raisin::Encoder;

my $enc = Raisin::Encoder->new;

is_deeply [sort keys %{ $enc->all }], [sort qw/json yaml text/], 'all';

my ($format, $class) = ('xml', 'Raisin::Encoder::Text');
ok $enc->register($format => $class), 'register';

is_deeply [sort keys %{ $enc->all }], [sort qw/json yaml text xml/], "all + $format";

is $enc->for($format), $class, "valid class for $format";

SKIP: {
    skip 'media_types_map_flat_hash: instable', 1;

    my %mtmflh = $enc->media_types_map_flat_hash;
    is_deeply \%mtmflh, {
        'application/json'   => "json",
        'json'               => "json",
        'text/json'          => "json",
        'text/x-json'        => "json",
        'application/x-yaml' => "yaml",
        'application/yaml'   => "yaml",
        'text/x-yaml'        => "yaml",
        'text/yaml'          => "yaml",
        'yaml'               => "yaml",
        'text/plain'         => "xml",
        'txt'                => "xml",
    }, 'media_types_map_flat_hash';
};

done_testing;
