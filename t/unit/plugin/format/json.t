
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../../../lib";

use Raisin;
use Raisin::Plugin::Format::JSON;

my @CASES = (
    {
        string => '{"str":"i-am-a-string"}',
        data => { str => 'i-am-a-string' },
    },
    {
        string => '{"str":["i","-","a","m","-","a","-","s","t","r","i","n","g"]}',
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
