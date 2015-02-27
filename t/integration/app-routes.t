
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common qw(GET POST PUT DELETE);
use Plack::Test;
use Plack::Util;
use Test::More;
use YAML 'Load';
use JSON 'decode_json';

use lib ("$Bin/../../examples/sample-app/lib");

my $app = Plack::Util::load_psgi("$Bin/../../examples/sample-app/script/restapp.psgi");

my @CASES = (
    {
        namespace => 'users',
        object => {
            name     => 'Obi-Wan Kenobi',
            password => 'somepassword',
            email    => 'ow.kenobi@jedi.com',
        },
        edit => {
            password => 'test',
        }
    },
    {
        namespace => 'hosts',
        object => {
            name    => 'tatooine.com',
            user_id => 1,
            state   => 'ok',
        },
        edit => {
            state => 'malfunc',
        }
    },
);

for my $case (@CASES) {
    my @IDS = ();
    my %NEW = %{ $case->{object} };

    test_psgi $app, sub {
        my $cb  = shift;

        subtest "GET /api/$case->{namespace}" => sub {
            my $res = $cb->(GET "/api/$case->{namespace}");
            if (!is $res->code, 200) {
                diag $res->content;
                BAIL_OUT 'FAILED!';
            }
            is $res->content_type, 'application/yaml';
            ok my $c = $res->content, 'content';
            ok my $o = Load($c), 'decode';
            @IDS = map { $_->{id} } grep { $_ } @{ $o->{data} };
            ok scalar @IDS, 'data';
        };

        subtest "GET /api/$case->{namespace}.json" => sub {
            my $res = $cb->(GET "/api/$case->{namespace}.json");
            if (!is $res->code, 200) {
                diag $res->content;
                BAIL_OUT 'FAILED!';
            }
            is $res->content_type, 'application/json';
            ok my $c = $res->content, 'content';
            ok my $o = decode_json($c), 'decode';
            @IDS = map { $_->{id} } grep { $_ } @{ $o->{data} };
            ok scalar @IDS, 'data';
        };

        subtest "POST /api/$case->{namespace}" => sub {
            my $res = $cb->(POST "/api/$case->{namespace}", [%NEW]);
            if (!is $res->code, 200) {
                diag $res->content;
                BAIL_OUT 'FAILED!';
            }
            ok my $c = $res->content, 'content';
            ok my $o = Load($c), 'decode';
            is $o->{success}, $IDS[-1] + 1, 'success';
            push @IDS, $o->{success};
        };

        subtest "GET /api/$case->{namespace}/$IDS[-1]" => sub {
            my $res = $cb->(GET "/api/$case->{namespace}/$IDS[-1]");
            if (!is $res->code, 200) {
                diag $res->content;
                BAIL_OUT 'FAILED!';
            }
            ok my $c = $res->content, 'content';
            ok my $o = Load($c), 'decode';
            is_deeply $o->{data}, \%NEW, 'data';
        };

        subtest "PUT /api/$case->{namespace}/$IDS[-1]" => sub {
            my $content_string = join '&',
                map { "$_=$case->{edit}{$_}" } keys %{ $case->{edit} };

            my $res = $cb->(
                PUT "/api/$case->{namespace}/$IDS[-1]",
                Content => $content_string,
                Content_Type => 'application/x-www-form-urlencoded'
            );

            my %EDITED = (
                %NEW,
                id => $IDS[-1],
                %{ $case->{edit} },
            );

            if (!is $res->code, 200) {
                diag $res->content;
                BAIL_OUT 'FAILED!';
            }
            ok my $c = $res->content, 'content';
            ok my $o = Load($c), 'decode';
            is_deeply $o->{data}, \%EDITED, 'data';
        };

        if ($case->{namespace} eq 'users') {
            subtest "GET /api/$case->{namespace}/all" => sub {
                my $res = $cb->(GET "/api/$case->{namespace}/all");
                is $res->code, 200;
                ok my $c = $res->content, 'content';
                ok my $o = Load($c), 'decode';
                @IDS = map { $_->{id} } grep { $_ } @{ $o->{data} };
                ok scalar @IDS, 'data';
            };

            subtest "PUT /api/users/$IDS[-1]/bump" => sub {
                my $res = $cb->(PUT "/api/users/$IDS[-1]/bump");
                if (!is $res->code, 200) {
                    diag $res->content;
                    BAIL_OUT 'FAILED!';
                }
                ok my $c = $res->content, 'content';
                ok my $o = Load($c), 'decode';
                ok $o->{success}, 'success';
            };

            subtest "GET /api/users/$IDS[-1]/bump" => sub {
                my $res = $cb->(GET "/api/users/$IDS[-1]/bump");
                if (!is $res->code, 200) {
                    diag $res->content;
                    BAIL_OUT 'FAILED!';
                }
                ok my $c = $res->content, 'content';
                ok my $o = Load($c), 'decode';
                ok $o->{data}, 'data';
            };
        }

        subtest "DELETE /api/$case->{namespace}/$IDS[0]" => sub {
            my $res = $cb->(DELETE "/api/$case->{namespace}/$IDS[0]");

            if (!is $res->code, 200) {
                diag $res->content;
                BAIL_OUT 'FAILED!';
            }
            ok my $c = $res->content, 'content';
            ok my $o = Load($c), 'decode';
            is_deeply $o, { success => 1 }, 'success';
        };

        subtest 'GET /404' => sub {
            my $res = $cb->(GET '/404');
            #note explain $res->content;
            is $res->code, 404;
        };
    };
}

done_testing;
