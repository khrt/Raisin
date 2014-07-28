
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin::Plugin::Format::JSON;
use Raisin::Plugin::Format::YAML;

my %struct = (
    letters => ['ё', 'z'],
);

subtest 'json' => sub {
    my $data = Raisin::Plugin::Format::JSON::serialize(undef, \%struct);
    my $back_struct = Raisin::Plugin::Format::JSON::deserialize(undef, $data);
    is_deeply $back_struct, \%struct;
};

subtest 'yaml' => sub {
    my $data = Raisin::Plugin::Format::YAML::serialize(undef, \%struct);
    my $back_struct = Raisin::Plugin::Format::YAML::deserialize(undef, $data);
    is_deeply $back_struct, \%struct;
};

done_testing;

