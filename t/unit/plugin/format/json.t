
use strict;
use warnings;

use Test::More;
use JSON qw(to_json from_json);

use Raisin;
use Raisin::Plugin::Format::JSON;

my @CASES = (
    {
        string => to_json({ str => 'i-am-a-string' }, { utf8 => 0 }),
        data => { str => 'i-am-a-string' },
    },
    {
        string => to_json({ str => [qw(i - a m - a - s t r i n g)] }, { utf8 => 0 }),
        data => { str => [qw(i - a m - a - s t r i n g)] },
    },
);

sub _make_object {
    my $caller = caller;
    my $app = Raisin->new(caller => $caller);
    Raisin::Plugin::Format::JSON->new($app)->build;
    $app;
}

my $app = _make_object();
isa_ok $app, 'Raisin', 'app';
isa_ok $app->serializer, 'Raisin::Plugin::Format::JSON', 'serializer';

is $app->serializer->content_type, 'application/json', 'content_type';

subtest 'serialize' => sub {
    for my $case (@CASES) {
        is_deeply $app->serializer->serialize($case->{data}), $case->{string};
    }
};

subtest 'deserialize' => sub {
    for my $case (@CASES) {
        is_deeply $app->serializer->deserialize($case->{string}), $case->{data};
    }
};

done_testing;
