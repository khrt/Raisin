
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Plack::Util;
use Test::More;
use YAML 'Load';
use JSON 'decode_json';

use lib ("$Bin/../../lib", "$Bin/../../examples/sample-app/lib");

my %NEW_USER = (
    name     => 'Obi-Wan Kenobi',
    password => 'somepassword',
    email    => 'ow.kenobi@jedi.com',
);
my @USER_IDS;

my $app = Plack::Util::load_psgi("$Bin/../../examples/sample-app/script/simple-restapp.pl");

test_psgi $app, sub {
    my $cb  = shift;

    subtest 'GET /api/user' => sub {
        my $res = $cb->(GET '/api/user');
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        is $res->content_type, 'application/yaml';
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        @USER_IDS = map { $_->{id} } grep { $_ } @{ $o->{data} };
        ok scalar @USER_IDS, 'data';
    };

    subtest 'GET /api/user.json' => sub {
        my $res = $cb->(GET '/api/user.json');
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        is $res->content_type, 'application/json';
        ok my $c = $res->content, 'content';
        ok my $o = decode_json($c), 'decode';
        @USER_IDS = map { $_->{id} } grep { $_ } @{ $o->{data} };
        ok scalar @USER_IDS, 'data';
    };

    subtest 'GET /api/user/all' => sub {
        my $res = $cb->(GET '/api/user/all');
        is $res->code, 200;
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        @USER_IDS = map { $_->{id} } grep { $_ } @{ $o->{data} };
        ok scalar @USER_IDS, 'data';
    };

    subtest 'POST /api/user' => sub {
        my $res = $cb->(POST '/api/user', [%NEW_USER]);
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        is $o->{success}, $USER_IDS[-1] + 1, 'success';
        push @USER_IDS, $o->{success};
    };

    subtest "GET /api/user/$USER_IDS[-1]" => sub {
        my $res = $cb->(GET "/api/user/$USER_IDS[-1]");
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        is_deeply $o->{data}, \%NEW_USER, 'data';
    };

    subtest "PUT /api/user/$USER_IDS[-1]" => sub {
        my $res = $cb->(
            PUT "/api/user/$USER_IDS[-1]",
            Content => "password=new",
            Content_Type => 'application/x-www-form-urlencoded'
        );

        my %EDITED_USER = (%NEW_USER, password => 'new', id => $USER_IDS[-1]);

        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        is_deeply $o->{data}, \%EDITED_USER, 'data';
    };

    subtest "PUT /api/user/$USER_IDS[-1]/bump" => sub {
        my $res = $cb->(PUT "/api/user/$USER_IDS[-1]/bump");
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        ok $o->{success}, 'success';
    };

    subtest "GET /api/user/$USER_IDS[-1]/bump" => sub {
        my $res = $cb->(GET "/api/user/$USER_IDS[-1]/bump");
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        ok $o->{data}, 'data';
    };

#    subtest 'GET /failed' => sub {
#        my $res = $cb->(GET '/failed?failed=FAILED');
#        is $res->code, 409;
#        ok my $c = $res->content, 'content';
#        ok my $o = Load($c), 'decode';
#        is $o->{data}, 'FAILED', 'data';
#    };

    subtest 'GET /404' => sub {
        my $res = $cb->(GET '/404');
        #note explain $res->content;
        is $res->code, 404;
    };
};

done_testing;
