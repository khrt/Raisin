
use strict;
use warnings;

use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use Time::HiRes qw(time);
use YAML;

use Raisin::API;
use Types::Standard qw(Int Str);

my $app = eval {
    my %DATA = (
        key => 'Initial data',
    );

    before sub {
        my $app = shift;
        $app->res->header('X-Before' => $app->req->param('key'));
    };

    before_validation sub {
        my $app = shift;
        $app->res->header('X-Time' => time);
    };

    after_validation sub {
        my $app = shift;
        $app->res->header('X-Diff' => time - $app->res->header('X-Time'));
    };

    after sub {
        my $app = shift;
        #my $data = { data => YAML::Load($app->res->body), after => 'OK', };
        #$app->res->body(YAML::Dump($data));
        $app->res->header('X-After' => $app->req->param('key'));
    };

    resource api => sub {
        params requires => { name => 'key', type => Int };
        get sub { \%DATA };
    };

    run;
};

BAIL_OUT $@ if $@;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/api?key=42');

    is $res->header('X-Before'), 42, 'before';
    #diag $res->header('X-Time');
    ok $res->header('X-Time'), 'before_validation';
    #diag $res->header('X-Diff');
    ok $res->header('X-Diff') < $res->header('X-Time'), 'after_validation';
    #is YAML::Load($res->content)->{after}, 'OK', 'content';
    is $res->header('X-After'), 42, 'after';
};

done_testing;
