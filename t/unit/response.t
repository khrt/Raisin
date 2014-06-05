
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../lib";

use Raisin;
use Raisin::Response;

use JSON;
use YAML;

my $caller = caller;
my $app = Raisin->new(caller => $caller);

#subtest 'serialize' => sub {
#
#};

subtest 'render' => sub {
    my $data = {
        key0 => 'value0',
        key1 => { subkey0 => 'subvalue0' },
        key2 => 2,
    };

    subtest 'JSON as default formatter' => sub {
        $app->api_format('json');
        my $r = Raisin::Response->new($app);

        ok $r->render(undef, $data);
        my $out = JSON::decode_json($r->body);
        is_deeply $out, $data, 'render';

        is $r->content_type, 'application/json', 'content type';
        ok $r->rendered, 'rendered';

        $r->{rendered} = 0;
    };

    subtest 'JSON' => sub {
        my $r = Raisin::Response->new($app);

        ok $r->render('json', $data);
        my $out = JSON::decode_json($r->body);
        is_deeply $out, $data, 'render';

        is $r->content_type, 'application/json', 'content type';
        ok $r->rendered, 'rendered';

        $r->{rendered} = 0;
    };

    subtest 'YAML' => sub {
        my $r = Raisin::Response->new($app);

        ok $r->render('yaml', $data);
        my $out = YAML::Load($r->body);
        is_deeply $out, $data, 'render';

        is $r->content_type, 'application/yaml', 'content type';
        ok $r->rendered, 'rendered';

        $r->{rendered} = 0;
    };

    subtest 'fallback text' => sub {
        my $r = Raisin::Response->new($app);
        ok $r->render('text', $data);

        is $r->content_type, 'text/plain', 'content type';
        ok $r->rendered, 'rendered';

        $r->{rendered} = 0;
    };

    subtest 'text' => sub {
        my $r = Raisin::Response->new($app);
        ok $r->render('text', 'text/plain');
        is $r->body, 'text/plain', 'render text';

        is $r->content_type, 'text/plain', 'content type';
        ok $r->rendered, 'rendered';

        $r->{rendered} = 0;
    };
};

subtest 'render error' => sub {
    subtest 'render_500' => sub {
        my $r = Raisin::Response->new($app);

        ok $r->render_500('My internal error');
        is $r->body, 'My internal error', 'render';
        is $r->code, 500, 'code';
        ok $r->rendered, 'rendered';

        $r->{rendered} = 0;
    };

    subtest 'render_404' => sub {
        my $r = Raisin::Response->new($app);

        ok $r->render_404('My nothing found');
        is $r->body, 'My nothing found', 'render';
        is $r->code, 404, 'code';
        ok $r->rendered, 'rendered';

        $r->{rendered} = 0;
    };

    subtest 'render_401' => sub {
        my $r = Raisin::Response->new($app);

        ok $r->render_401('My unauthorized');
        is $r->body, 'My unauthorized', 'render';
        is $r->code, 401, 'code';
        ok $r->rendered, 'rendered';

        $r->{rendered} = 0;
    };
};

done_testing;
