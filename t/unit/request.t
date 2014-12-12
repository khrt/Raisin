
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use HTTP::Message::PSGI;
use HTTP::Request;

use Types::Standard qw(Str Int Any);

use YAML qw();
use JSON qw();

use lib "$Bin/../../lib";

use Raisin;
use Raisin::Request;
use Raisin::Routes;

my %DATA_PATH = (id => 42);
my %DATA_GET = (param => 'ok');
my %DATA_POST = (
    %DATA_GET,
    string => 'data0', array => [0, 1, 2], hash => { key => 'value' },
);

my $rr_path = '/api/:id';
my $rr = Raisin::Routes->new;
$rr->add(
    method => 'GET',
    path => $rr_path,
    params => [
        requires => { name => 'param', type => Str },
    ],
    named => [
        require => { name => 'id', type => Int }
    ],
    code => sub {}
);
$rr->add(
    method => 'POST',
    path => $rr_path,
    params => [
        requires => { name => 'param', type => Str },
        optional => { name => 'string', type => Any },
        optional => { name => 'array', type => Any },
        optional => { name => 'hash', type => Any },
    ],
    named => [
        require => { name => 'id', type => Int }
    ],
    code => sub {}
);
$rr->add(
    method => 'PUT',
    path => $rr_path,
    params => [
        requires => { name => 'param', type => Str },
        optional => { name => 'string', type => Any },
        optional => { name => 'array', type => Any },
        optional => { name => 'hash', type => Any },
    ],
    named => [
        require => { name => 'id', type => Int }
    ],
    code => sub {}
);
my $route_get = $rr->routes->[0];
my $route_post = $rr->routes->[1];
my $route_put = $rr->routes->[2];

my @CASES = (
    # POST Form
    {
        input => {
            method => 'POST',
            headers => ['Accept' => '*/*', 'Content_Type' => 'application/x-www-form-urlencoded'],
            content => \%DATA_POST,
            route => $route_post,
        },
        expected => {
            accept => undef,
            deserialize => \%DATA_POST,
            prepare_params => { %DATA_PATH, %DATA_POST, array => sprintf('ARRAY(0x%x)', $DATA_POST{array}), hash => sprintf('HASH(0x%x)', $DATA_POST{hash}) },
        },
    },
    # POST JSON
    {
        input => {
            method => 'POST',
            headers => ['Accept' => '*/*', 'Content_Type' => 'application/json'],
            content => \%DATA_POST,
            route => $route_post,
        },
        expected => {
            accept => undef,
            deserialize => \%DATA_POST,
            prepare_params => { %DATA_PATH, %DATA_POST, },
        },
    },
    # POST YAML
    {
        input => {
            method => 'POST',
            headers => ['Accept' => '*/*', 'Content_Type' => 'application/yaml'],
            content => \%DATA_POST,
        route => $route_post,
        },
        expected => {
            accept => undef,
            deserialize => \%DATA_POST,
            prepare_params => { %DATA_PATH, %DATA_POST, },
        },
    },

    # PUT YAML
    {
        input => {
            method => 'PUT',
            headers => ['Accept' => '*/*', 'Content_Type' => 'application/yaml'],
            content => \%DATA_POST,
            route => $route_put,
        },
        expected => {
            accept => undef,
            deserialize => \%DATA_POST,
            prepare_params => { %DATA_PATH, %DATA_POST, },
        },
    },

    # GET *
    {
        input => {
            method => 'GET',
            headers => ['Accept' => '*/*'],
            route => $route_get,
        },
        expected => {
            accept => undef,
            deserialize => undef,
            prepare_params => { %DATA_PATH, %DATA_GET, },
        },
    },
    # GET text/plain
    {
        input => {
            method => 'GET',
            headers => ['Accept' => 'text/plain'],
            route => $route_get,
        },
        expected => {
            accept => 'text',
            deserialize => undef,
            prepare_params => { %DATA_PATH, %DATA_GET, },
        },
    },
    # GET JSON
    {
        input => {
            method => 'GET',
            headers => ['Accept' => 'application/json'],
            route => $route_get,
        },
        expected => {
            accept => 'json',
            deserialize => undef,
            prepare_params => { %DATA_PATH, %DATA_GET, },
        },
    },
    # GET YAML
    {
        input => {
            method => 'GET',
            headers => ['Accept' => 'application/yaml'],
            route => $route_get,
        },
        expected => {
            accept => 'yaml',
            deserialize => undef,
            prepare_params => { %DATA_PATH, %DATA_GET, },
        },
    },
    # GET XML
    {
        input => {
            method => 'GET',
            headers => ['Accept' => 'application/xml'],
            route => $route_get,
        },
        expected => {
            accept => 'application/xml',
            deserialize => undef,
            prepare_params => { %DATA_PATH, %DATA_GET, },
        },
    }
);

sub _make_object {
    my $http_req = shift;
    my $caller = caller;
    my $app = Raisin->new(caller => $caller);
    Raisin::Request->new($app, req_to_psgi($http_req));
}

sub _make_request {
    my $input = shift;

    my %headers = @{ $input->{headers} };
    my $content = $input->{content};

    if ($content && $headers{Content_Type} =~ 'x-www-form-urlencoded') {
        $content = join '&', map { "$_=$content->{$_}" } keys %$content;
    }
    elsif ($content && $headers{Content_Type} =~ 'json') {
        $content = JSON::encode_json($content);
    }
    elsif ($content && $headers{Content_Type} =~ 'yaml') {
        $content = YAML::Dump($content);
    }

    my $qs = join '&', map { "$_=$DATA_GET{$_}" } keys %DATA_GET;;
    my $uri = "/api/$DATA_PATH{id}?$qs";

    HTTP::Request->new($input->{method}, $uri, $input->{headers}, $content);
}

subtest 'accept_format' => sub {
    for my $case (@CASES) {
        my $title = $case->{expected}{accept} || 'any';

        my $http_req = _make_request($case->{input});
        my $req = _make_object($http_req);
        #isa_ok $req, 'Raisin::Request', 'request';

        is $req->accept_format, $case->{expected}{accept}, "accept_format: $title";
    }
};

subtest 'deserialize' => sub {
    for my $case (@CASES) {
        next if $case->{input}{method} eq 'GET';

        my $http_req = _make_request($case->{input});
        my $req = _make_object($http_req);
        #isa_ok $req, 'Raisin::Request', 'request';

        # XXX:
        next if $req->content_type eq 'application/x-www-form-urlencoded';

        is_deeply $req->deserialize($req->content),
            $case->{expected}{deserialize}, 'deserialize: ' . $req->content_type;
    }
};

subtest 'prepare_params, +declared_params' => sub {
    for my $case (@CASES) {
        my $title = "$case->{input}{method} " . ($case->{expected}{accept} || '--');

        subtest $title => sub {
            my $http_req = _make_request($case->{input});
            my $req = _make_object($http_req);
            isa_ok $req, 'Raisin::Request', 'request';

            my $r = $case->{input}{route};

            ok $r->match($req->method, $req->path), "match: ${ \$r->path }";

            ok $req->prepare_params($r->params, $r->named), 'prepare_params';
            is_deeply $req->declared_params, $case->{expected}{prepare_params},
                'declared params';
        };
    }
};

done_testing;
