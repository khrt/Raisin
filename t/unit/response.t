
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use Data::Dumper;
use JSON qw();
use YAML qw();

use lib "$Bin/../../lib";

use Raisin;
use Raisin::Response;

my %DATA = (
    string => 'data0', array => [0, 1, 2], hash => { key => 'value' },
);

my @CASES = (
    {
        input => {
            body => \%DATA,
            content_type => 'application/json',
            format => 'json',
        },
        expected => {
            body => JSON::to_json(\%DATA, { utf8 => 0 }),
            content_type => 'application/json',
        },
    },
    {
        input => {
            body => \%DATA,
            content_type => 'application/json',
            format => 'json',
            status => 201,
        },
        expected => {
            body => JSON::to_json(\%DATA, { utf8 => 0 }),
            content_type => 'application/json',
        },
    },

    {
        input => {
            body => \%DATA,
            content_type => 'application/yaml',
            format => 'yaml',
            status => 202,
        },
        expected => {
            body => YAML::Dump(\%DATA),
            content_type => 'application/yaml',
        },
    },
    {
        input => {
            body => \%DATA,
            content_type => 'application/yaml',
            format => 'yaml',
            status => 203,
        },
        expected => {
            body => YAML::Dump(\%DATA),
            content_type => 'application/yaml',
        },
    },

    {
        input => {
            body => \%DATA,
            content_type => 'text/plain',
            format => 'text',
            status => 204,
        },
        expected => {
            body => Data::Dumper->new([\%DATA], ['data'])->Sortkeys(1)->Purity(1)->Terse(1)->Deepcopy(1)->Dump,
            content_type => 'text/plain',
        },
    },
    {
        input => {
            body => \%DATA,
            content_type => 'text/plain',
            format => 'text',
            status => 400,
        },
        expected => {
            body => Data::Dumper->new([\%DATA], ['data'])->Sortkeys(1)->Purity(1)->Terse(1)->Deepcopy(1)->Dump,
            content_type => 'text/plain',
        },
    },
);

sub _make_object {
    my $object = shift;
    my $caller = caller;
    my $app = Raisin->new(caller => $caller);
    Raisin::Response->new($app);
}

subtest 'serialize' => sub {
    for my $case (@CASES) {
        my $resp = _make_object;

        subtest $case->{expected}{content_type} => sub {
            is $resp->serialize($case->{input}{format}, $case->{input}{body}),
                $case->{expected}{body}, "serialize: $case->{input}{format}";

            is $resp->content_type, $case->{expected}{content_type},
                "content_type: $case->{expected}{content_type}";
        };

    }
};

subtest 'render' => sub {
    for my $case (@CASES) {
        subtest $case->{input}{format} => sub {
            my $resp = _make_object;
            $resp->body(\%DATA);

            ok $resp->format($case->{input}{format}), 'format';

            if ($case->{input}{status}) {
                ok $resp->status($case->{input}{status}), 'set status';
            }

            ok $resp->render, 'render';

            is $resp->body, $case->{expected}{body}, 'body';
            is $resp->content_type, $case->{expected}{content_type}, 'content_type';
            is $resp->status, $case->{input}{status} || 200, 'status';

            ok $resp->rendered, 'rendered';
        };
    }
};

subtest 'render_401' => sub {
    my $resp = _make_object;
    ok $resp->render_401;

    is $resp->status, 401, 'status';
    is $resp->body, 'Unauthorized', 'body';
    ok $resp->rendered, 'rendered';
};

subtest 'render_404' => sub {
    my $resp = _make_object;
    ok $resp->render_404;

    is $resp->status, 404, 'status';
    is $resp->body, 'Nothing found', 'body';
    ok $resp->rendered, 'rendered';
};

subtest 'render_500' => sub {
    my $resp = _make_object;
    ok $resp->render_500;

    is $resp->status, 500, 'status';
    is $resp->body, 'Internal error', 'body';
    ok $resp->rendered, 'rendered';
};

subtest 'render_error' => sub {
    my $resp = _make_object;
    ok $resp->render_error('403', 'Forbiden?'), 'render_error: 403 Forbiden?';

    is $resp->status, 403, 'status';
    is $resp->body, 'Forbiden?', 'body';
    ok $resp->rendered, 'rendered';
};

done_testing;
