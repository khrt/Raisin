
use strict;
use warnings;

use HTTP::Message::PSGI;
use HTTP::Request::Common qw(GET);
use Test::More;
use Types::Standard qw(Int);

use Raisin;
use Raisin::Param;
use Raisin::Request;
use Raisin::Routes::Endpoint;

{
    no strict 'refs';
    *Raisin::log = sub { note(sprintf $_[1], @_[2 .. $#_]) };
}

subtest 'precedence' => sub {
    my $r = Raisin::Routes::Endpoint->new(
        method => 'GET',
        path => '/user/:id',
        params => [
            Raisin::Param->new(
                named => 1,
                type => 'requires',
                spec => { name => 'id', type => Int },
            ),
            Raisin::Param->new(
                named => 0,
                type => 'optional',
                spec => { name => 'id', type => Int },
            ),
        ],
        code => sub {},
    );

    my @CASES = (
        {
            env => {
                %{ GET('/user/1?id=2')->to_psgi },
                'raisinx.body_params' => { id => 3 },
            },
            expected => 1,
        },
        {
            env => {
                %{ GET('/user/?id=2')->to_psgi },
                'raisinx.body_params' => { id => 3 },
            },
            expected => 2,
        },
        {
            env => {
                %{ GET('/user/')->to_psgi },
                'raisinx.body_params' => { id => 3 },
            },
            expected => 3,
        },
        {
            env => {
                %{ GET('/user/')->to_psgi },
            },
            expected => undef,
        },

    );

    for my $case (@CASES) {
        my $req = Raisin::Request->new($case->{env});

        $r->match($case->{env}{REQUEST_METHOD}, $case->{env}{PATH_INFO});
        $req->prepare_params($r->params, $r->named);

        is $req->raisin_parameters->{id}, $case->{expected};
    }
};

subtest 'validation' => sub {
    my $r = Raisin::Routes::Endpoint->new(
        method => 'GET',
        path => '/user',
        params => [
            Raisin::Param->new(
                type => 'required',
                spec => { name => 'req', type => Int },
            ),
            Raisin::Param->new(
                type => 'optional',
                spec => { name => 'opt1', type => Int },
            ),
            Raisin::Param->new(
                type => 'optional',
                spec => { name => 'opt2', type => Int, default => 42 },
            ),
        ],
        code => sub {},
    );

    my @CASES = (
        # required, not set
        # optional 1, not set
        # optional 2, not set
        {
            env => GET('/user/')->to_psgi,
            expected => {
                ret => undef,
                pp => {},
            },
        },
        # required, set
        # optional 1, not set
        # optional 2, not set
        {
            env => GET('/user/?req=1')->to_psgi,
            expected => {
                ret => 1,
                pp => { req => 1, opt2 => 42 },
            },
        },
        # required, set
        # optional 1, set
        # optional 2, not set
        {
            env => GET('/user/?req=1&opt1=2')->to_psgi,
            expected => {
                ret => 1,
                pp => { req => 1, opt1 => 2, opt2 => 42 },
            },
        },
        # required, set
        # optional 2, set
        {
            env => GET('/user/?req=1&opt2=2')->to_psgi,
            expected => {
                ret => 1,
                pp => { req => 1, opt2 => 2 },
            },
        },
    );

    for my $case (@CASES) {
        my $req = Raisin::Request->new($case->{env});

        $r->match($case->{env}{REQUEST_METHOD}, $case->{env}{PATH_INFO});
        is $req->prepare_params($r->params, $r->named), $case->{expected}{ret};

        next unless $case->{expected}{ret};

        is_deeply $req->declared_params, $case->{expected}{pp};
    }
};

done_testing;
