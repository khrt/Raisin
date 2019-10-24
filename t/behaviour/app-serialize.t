
use utf8;
use strict;
use warnings;

use Data::Dumper;
use Encode qw(decode_utf8);
use HTTP::Request::Common qw(GET);
use Plack::Test;
use Test::More;
use YAML qw(Load);
use JSON::MaybeXS;

use Raisin::API;
use Types::Standard qw(Int Str);

my %DATA = (
    name     => 'Bruce Wayne',
    password => 'b47m4n',
    email    => 'bruce@wayne.name',
    enemy    => "Mr \x{2603}",
);

my $app = eval {
    resource api => sub {
        get sub { { params => \%DATA, } };
    };
    run;
};

{
    no strict 'refs';
    no warnings qw(once redefine);
    *Raisin::log = sub { note(sprintf $_[1], @_[2 .. $#_]) };
}

BAIL_OUT $@ if $@;

test_psgi $app, sub {
    my $cb = shift;
    my ( $res, $pp );

    subtest 'application/x-yaml' => sub {
        $res = $cb->( GET '/api', Accept => 'application/x-yaml' );

        is $res->header('Content-Type'), 'application/x-yaml',
          'content-type';
        ok $pp = Load( decode_utf8($res->content) ), 'decode';
        is_deeply $pp->{params}, \%DATA, 'match';

        $res = $cb->( GET '/api.yaml' );

        is $res->header('Content-Type'), 'application/x-yaml',
          'content-type';
        ok $pp = Load( decode_utf8($res->content) ), 'decode';
        is_deeply $pp->{params}, \%DATA, 'match';
    };

    subtest 'application/json' => sub {
        $res = $cb->( GET '/api', Accept => 'application/json' );

        is $res->header('Content-Type'), 'application/json', 'content-type';
        ok $pp = decode_json( $res->content ), 'decode';
        is_deeply $pp->{params}, \%DATA, 'match';

        $res = $cb->( GET '/api.json' );

        is $res->header('Content-Type'), 'application/json', 'content-type';
        ok $pp = decode_json( $res->content ), 'decode';
        is_deeply $pp->{params}, \%DATA, 'match';
    };
};

subtest 'text/plain' => sub {
    my $TEXT_DATA = Data::Dumper->new([{ params => \%DATA }], ['data'])
        ->Sortkeys(1)
        ->Purity(1)
        ->Terse(1)
        ->Deepcopy(1)
        ->Dump;
    $TEXT_DATA =~ s/\s//g;

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/api', Accept => 'text/plain');

        is $res->header('Content-Type'), 'text/plain; charset=utf-8', 'content-type';
        my $content = $res->content;
        $content =~ s/\s//g;
        is $content, $TEXT_DATA, 'match';
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/api.txt');

        is $res->header('Content-Type'), 'text/plain; charset=utf-8', 'content-type';
        my $content = $res->content;
        $content =~ s/\s//g;
        is $content, $TEXT_DATA, 'match';
    };
};

subtest 'unacceptable' => sub {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/api', Accept => 'application/xml');

        is $res->code, 406, 'status';
    };

    my $app = eval {
        api_format 'json';
        resource api => sub {
            get sub { { params => \%DATA, } };
        };

        run;
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/api', Accept => 'application/x-yaml');

        is $res->code, 406, 'status';
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/api', Accept => 'application/json');

        is $res->code, 200, 'status';
    };
};

done_testing;
