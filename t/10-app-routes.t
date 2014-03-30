
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Plack::Util;
use Test::More;
use YAML 'Load';

use lib "$Bin/../lib";

my %NEW_USER = (
    name     => 'Obi-Wan Kenobi',
    password => 'somepassword',
    email    => 'ow.kenobi@jedi.com',
);
my @USER_IDS;

my $app = Plack::Util::load_psgi("$Bin/../examples/singular/routes.pl");

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET '/user');

    subtest 'GET /user' => sub {
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        @USER_IDS = map { $_->{id} } grep { $_ } @{ $o->{data} };
        ok scalar @USER_IDS, 'data';
    };
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET '/user/all');

    subtest 'GET /user/all' => sub {
        is $res->code, 200;
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        @USER_IDS = map { $_->{id} } grep { $_ } @{ $o->{data} };
        ok scalar @USER_IDS, 'data';
    };
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(POST '/user', [%NEW_USER]);

    subtest 'POST /user' => sub {
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        is $o->{success}, $USER_IDS[-1] + 1, 'success';
        push @USER_IDS, $o->{success};
    };
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/user/$USER_IDS[-1]");

    subtest "GET /user/$USER_IDS[-1]" => sub {
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        is_deeply $o->{data}, \%NEW_USER, 'data';
    };
};

test_psgi $app, sub {
    my $cb  = shift;

    my $res = $cb->(
        PUT "/user/$USER_IDS[-1]",
        Content => "password=new",
        Content_Type => 'application/x-www-form-urlencoded'
    );

    subtest "PUT /user/$USER_IDS[-1]" => sub {
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        is $o->{success}, 1, 'success';
    };
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(PUT "/user/$USER_IDS[-1]/bump");

    subtest "PUT /user/$USER_IDS[-1]/bump" => sub {
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        ok $o->{success}, 'success';
    };
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/user/$USER_IDS[-1]/bump");

    subtest "GET /user/$USER_IDS[-1]/bump" => sub {
        if (!is $res->code, 200) {
            diag $res->content;
            BAIL_OUT 'FAILED!';
        }
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        ok $o->{data}, 'data';
    };
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET '/failed?failed=FAILED');

    subtest 'GET /failed' => sub {
        is $res->code, 409;
        ok my $c = $res->content, 'content';
        ok my $o = Load($c), 'decode';
        is $o->{data}, 'FAILED', 'data';
    };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/404');

    subtest 'GET /404' => sub {
        #note explain $res->content;
        is $res->code, 404;
    };
};

done_testing;
