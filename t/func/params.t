
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Plack::Util;
use Test::More;

use YAML;
use JSON;

use lib "$Bin/../../lib";

my %PARAMS = (
    param0 => 0,
    param1 => 1,
    param2 => 'value1',
    param3 => ['value2.0', 'value2.1'],
);

my $json_app = eval {
    use Raisin::API;
    use Types::Standard qw(Int Str);

    api_format 'JSON';
    params [
        requires => ['param0', Int],
        required => ['param1', Int],

        optional => ['param2', Str],
        optional => ['param3', Str],
    ],
    post => sub { shift };
    run;
};

#my $yaml_app = eval {
#    use Raisin::API;
#    use Types::Standard qw(Int Str);
#
#    api_format 'YAML';
#    post params => [
#        requires => ['param0', Int],
#        required => ['param1', Int],
#
#        optional => ['param2', Str],
#        optional => ['param3', Str],
#    ],
#    sub { shift };
#    run;
#};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $req = encode_json({ param1 => 0 });
    my $res = $cb->(
        POST '/',
        Content => $req,
        Content_Type => 'application/json'
    );

    #note $res->content_type;

    is($res->code, 400, 'Invalid params');
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $req = encode_json({ param0 => 0, param1 => 1 });
    my $res = $cb->(
        POST '/',
        Content => $req,
        Content_Type => 'application/json'
    );

    #note $res->content_type;

    my %STANDARD = (
        param0 => 0,
        param1 => 1,
        param2 => undef,
        param3 => undef,
    );

    my $data = decode_json($res->content);
    is_deeply $data, \%STANDARD, 'POST JSON';
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $req = encode_json(\%PARAMS);
    my $res = $cb->(
        POST '/',
        Content => $req,
        Content_Type => 'application/json'
    );

    #note $res->content_type;

    my $data = decode_json($res->content);
    is_deeply $data, \%PARAMS, 'POST JSON';
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $req = Dump(\%PARAMS);
    my $res = $cb->(
        POST '/',
        Content => $req,
        Content_Type => 'application/yaml'
    );

    #note $res->content_type;
    #note $res->content;

    my $data = decode_json($res->content);
    is_deeply $data, \%PARAMS, 'POST YAML';
};

test_psgi $json_app, sub {
    my $cb  = shift;
    my $res = $cb->(
        POST '/',
        Content => [%PARAMS],
    );

    my $data = decode_json($res->content);
    is_deeply $data, \%PARAMS, 'POST Form input';
};

done_testing;
