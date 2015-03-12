
use strict;
use warnings;

use Test::More;

use Raisin;
use Raisin::Plugin::Format::TEXT;

my @CASES = (
    {
        string => "{'str'=>'i-am-a-string'}",
        data => { str => 'i-am-a-string' },
    },
    {
        string => "{'str'=>['i','-','a','m','-','a','-','s','t','r','i','n','g']}",
        data => { str => [qw(i - a m - a - s t r i n g)] },
    },
);

sub _make_object {
    my $caller = caller;
    my $app = Raisin->new(caller => $caller);
    Raisin::Plugin::Format::TEXT->new($app)->build;
    $app;
}

my $app = _make_object();
isa_ok $app, 'Raisin', 'app';
isa_ok $app->serializer, 'Raisin::Plugin::Format::TEXT', 'serializer';

is $app->serializer->content_type, 'text/plain', 'content_type';

subtest 'serialize' => sub {
    for my $case (@CASES) {
        my $s = $app->serializer->serialize($case->{data});
        $s =~ s/[\r\n\s]//g;

        is_deeply $s, $case->{string};
    }
};

subtest 'deserialize' => sub {
    for my $case (@CASES) {
        is_deeply $app->serializer->deserialize($case->{string}), $case->{string};
    }
};

done_testing;
