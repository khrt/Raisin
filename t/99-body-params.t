
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Plack::Util;
use Test::More;

use YAML;
use JSON;

use lib "$Bin/../lib";

my %params = (
    param1 => 'value1',
    param2 => ['value2.0', 'value2.1'],
);

my $json_app = eval {
    use Raisin::API;
    use Raisin::Types;
    api_format 'JSON';
    post params => [
        optional => ['param1', $Raisin::Types::String],
        optional => ['param2', $Raisin::Types::String],
    ],
    sub { shift };
    run;
};

#my $yaml_app = eval {
#    use Raisin::API;
#    use Raisin::Types;
#    api_format 'YAML';
#    post params => [
#        optional => ['param1', $Raisin::Types::String],
#        optional => ['param2', $Raisin::Types::String],
#    ],
#    sub { shift };
#    run;
#};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $req = encode_json(\%params);
    my $res = $cb->(
        POST '/',
        Content => $req,
        Content_Type => 'application/json'
    );

    #note explain $res->content_type;

    my $data = decode_json($res->content);
    is_deeply $data, \%params, 'POST JSON';
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $req = Dump(\%params);
    my $res = $cb->(
        POST '/',
        Content => $req,
        Content_Type => 'application/yaml'
    );

    #note explain $res->content_type;
    #note explain $res->content;

    like $res->content, qr/500/, 'POST YAML FAILED';
    #my $data = Load($res->content);
    #is_deeply $data, \%params, 'POST YAML';
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $res = $cb->(
        POST '/',
        Content => [%params],
    );

    my $data = decode_json($res->content);
    is_deeply $data, \%params, 'POST Form input';
};

done_testing;
