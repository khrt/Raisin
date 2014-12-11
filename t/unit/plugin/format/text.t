
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use lib "$Bin/../../../../lib";

use Raisin;
use Raisin::Plugin::Format::TEXT;


my @CASES = (
    {
        string => "{\n  'str' => 'i-am-a-string'\n}\n",
        data => { str => 'i-am-a-string' },
    },
    {
        string => <<EOF,
{
  'str' => [
             'i',
             '-',
             'a',
             'm',
             '-',
             'a',
             '-',
             's',
             't',
             'r',
             'i',
             'n',
             'g'
           ]
}
EOF
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
        is_deeply $app->serializer->serialize($case->{data}), $case->{string};
    }
};

subtest 'deserialize' => sub {
    for my $case (@CASES) {
        is_deeply $app->serializer->deserialize($case->{string}), $case->{string};
    }
};

done_testing;
