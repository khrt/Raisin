
use utf8;
use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use HTTP::Request::Common qw(POST);
use HTTP::Status qw(:constants);
use JSON::MaybeXS;
use Plack::Test;
use Test::More;
use Types::Standard qw(Int Str);
use YAML qw(Dump Load);

use Raisin::API;

my $app = eval {
    resource api => sub {
        params(
            requires('name', type => Str, desc => 'User name'),
            requires('password', type => Str, desc => 'User password'),
            optional('email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email'),
            optional('enemy', type => Str, default => undef, desc => 'Enemy'),
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
    name     => 'Bruce Wayne',
    password => 'b47m4n',
    email    => 'bruce@wayne.name',
    enemy    => "Mr \x{2603}",
);

BAIL_OUT $@ if $@;

test_psgi $app, sub {
    my $cb = shift;

    subtest 'application/yaml' => sub {
        my $res = $cb->(POST '/api', 'Content-Type' => 'application/yaml',
            Content => encode_utf8(Dump(\%DATA))
        );

        is $res->header('Content-Type'), 'application/x-yaml', 'content-type';
        my $pp = Load( decode_utf8($res->content) );
        is_deeply $pp->{params}, \%DATA, 'parameters match';
    };

    subtest 'application/json' => sub {
        my $res = $cb->(POST '/api', 'Content-Type' => 'application/json',
            Content => encode_json(\%DATA));

        is $res->header('Content-Type'), 'application/x-yaml', 'content-type';
        my $pp = Load( decode_utf8($res->content) );
        is_deeply $pp->{params}, \%DATA, 'parameters match';
    };

    subtest 'x-www-form-urlencoded' => sub {
        my $res = $cb->(POST '/api', [%DATA]);
        is $res->code, HTTP_UNSUPPORTED_MEDIA_TYPE, 'unsupported';
    };
};

done_testing;
