
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

my $app = eval {
    use Raisin::API;
    use Types::Standard qw(Int Str);

    api_format 'JSON';
    params(
        requires => { name => 'param0', type => Int },
        required => { name => 'param1', type => Int },

        optional => { name => 'param2', type => Str },
        optional => { name => 'param3', type => Str },
    );
    post sub { shift };
    run;
};

test_psgi $app, sub {
    my $cb  = shift;

    subtest 'invalid params' => sub {
        my $req = encode_json({ param1 => 0 });
        my $res = $cb->(
            POST '/', Content => $req, Content_Type => 'application/json'
        );

        #note $res->content_type;
        is($res->code, 400, 'Invalid params');
    };

    subtest 'post required params JSON' => sub {
        my $req = encode_json({ param0 => 0, param1 => 1 });
        my $res = $cb->(
            POST '/',
            Content => $req,
            Content_Type => 'application/json',
            Accept => 'application/json'
        );

        my %STANDARD = (
            param0 => 0,
            param1 => 1,
            param2 => undef,
            param3 => undef,
        );

        my $data = decode_json($res->content);
        is_deeply $data, \%STANDARD, 'POST JSON';
    };

    subtest 'post all params JSON' => sub {
        my $req = encode_json(\%PARAMS);
        my $res = $cb->(
            POST '/',
            Content => $req,
            Content_Type => 'application/json',
            Accept => 'application/json'
        );

        my $data = decode_json($res->content);
        is_deeply $data, \%PARAMS, 'POST JSON';
    };

    subtest 'post all params YAML' => sub {
        my $req = Dump(\%PARAMS);
        my $res = $cb->(
            POST '/',
            Content => $req,
            Content_Type => 'application/yaml',
            Accept => 'application/json'
        );

        my $data = decode_json($res->content);
        is_deeply $data, \%PARAMS, 'POST YAML';
    };

    subtest 'post params as form data' => sub {
        my $res = $cb->(POST '/', Content => [%PARAMS], Accept => 'application/json');

        my $data = decode_json($res->content);
        is_deeply $data, \%PARAMS, 'POST Form input';
    };
};

done_testing;
