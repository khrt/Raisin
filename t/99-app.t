
use strict;
use warnings;

use FindBin '$Bin';
use HTTP::Request::Common;
use Plack::Test;
use Test::More;

use lib "$Bin/../lib";

my $app;
my $content;

open my $fh, '<', "$Bin/../eg/simple/simple.pl";
while (<$fh>) {
    $content .= $_;
}
close $fh;

$app = eval $content;


my $t = Plack::Test->create($app);

my $res = $t->request(GET "/user/2");
diag $res->content;

