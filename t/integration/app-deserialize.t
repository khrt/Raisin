
use strict;
use warnings;

use HTTP::Request::Common qw(POST);
use Plack::Test;
use Test::More;
use YAML;
use JSON;

use Raisin::API;
use Types::Standard qw(Int Str);

my $app = eval {
    resource api => sub {
        params(
            requires => { name => 'name', type => Str, desc => 'User name' },
            requires => { name => 'password', type => Str, desc => 'User password' },
            optional => { name => 'email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email' },
        );
        post sub {
            my $params = shift;
            { params => $params, };
        };
    };

    run;
};

my %DATA = (
    name => 'Bruce Wayne',
    password => 'b47m4n',
    email => 'bruce@wayne.name',
);

BAIL_OUT $@ if $@;

subtest 'application/yaml' => sub {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(POST '/api', 'Content-Type' => 'application/yaml',
            Content => Dump(\%DATA));

        is $res->header('Content-Type'), 'application/yaml', 'content-type';
        ok my $pp = Load($res->content), 'decode';
        is_deeply $pp->{params}, \%DATA, 'match';
    };
};

subtest 'application/json' => sub {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(POST '/api', 'Content-Type' => 'application/json',
            Content => encode_json(\%DATA));

        is $res->header('Content-Type'), 'application/yaml', 'content-type';
        ok my $pp = Load($res->content), 'decode';
        is_deeply $pp->{params}, \%DATA, 'match';
    };
};

subtest 'x-www-form-urlencoded' => sub {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(POST '/api', [%DATA]);

        is $res->header('Content-Type'), 'application/yaml', 'content-type';
        ok my $pp = Load($res->content), 'decode';
        is_deeply $pp->{params}, \%DATA, 'match';
    };
};

done_testing;
