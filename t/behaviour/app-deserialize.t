
use strict;
use warnings;

use HTTP::Request::Common qw(POST);
use HTTP::Status qw(:constants);
use JSON;
use Plack::Test;
use Test::More;
use Types::Standard qw(Int Str);
use YAML;

use Raisin::API;

my $app = eval {
    resource api => sub {
        params(
            requires('name', type => Str, desc => 'User name'),
            requires('password', type => Str, desc => 'User password'),
            optional('email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email'),
        );
        post sub {
            my $params = shift;
            { params => $params, };
        };
    };

    run;
};

{
    no strict 'refs';
    no warnings qw(once redefine);
    *Raisin::log = sub { note(sprintf $_[1], @_[2 .. $#_]) };
}

my %DATA = (
    name => 'Bruce Wayne',
    password => 'b47m4n',
    email => 'bruce@wayne.name',
);

BAIL_OUT $@ if $@;

test_psgi $app, sub {
    my $cb = shift;

    subtest 'application/yaml' => sub {
        my $res = $cb->(POST '/api', 'Content-Type' => 'application/yaml',
            Content => Dump(\%DATA));

        is $res->header('Content-Type'), 'application/x-yaml', 'content-type';
        my $pp = Load($res->content);
        is_deeply $pp->{params}, \%DATA, 'parameters match';
    };

    subtest 'application/json' => sub {
        my $res = $cb->(POST '/api', 'Content-Type' => 'application/json',
            Content => encode_json(\%DATA));

        is $res->header('Content-Type'), 'application/x-yaml', 'content-type';
        my $pp = Load($res->content);
        is_deeply $pp->{params}, \%DATA, 'parameters match';
    };

    subtest 'x-www-form-urlencoded' => sub {
        my $res = $cb->(POST '/api', [%DATA]);
        is $res->code, HTTP_UNSUPPORTED_MEDIA_TYPE, 'unsupported';
    };
};

done_testing;
