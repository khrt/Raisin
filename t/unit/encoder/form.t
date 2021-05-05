
use strict;
use warnings;

use HTTP::Message::PSGI;
use HTTP::Request::Common;
use Plack::Request;
use Test::More;

use Raisin::Encoder::Form;

subtest 'detectable_by' => sub {
    my @ct = Raisin::Encoder::Form->detectable_by;
    is_deeply $ct[0], [qw(application/x-www-form-urlencoded multipart/form-data)];
};

subtest 'deserialize' => sub {
    my @CASES = (
        # form-urlencoded
        {
            env => POST('http://www.perl.org/survey.cgi', Content => [ name => 'Bruce Wayne' ])->to_psgi,
            expected => { name => 'Bruce Wayne' },
        },
        # form-data
        {
            env => POST('http://www.perl.org/survey.cgi', Content_Type => 'form-data', Content => [ name => 'Bruce Wayne' ])->to_psgi,
            expected => { name => 'Bruce Wayne' },
        }
    );
    for my $c (@CASES) {
        my $req  = Plack::Request->new( $c->{env} );
        my $data = Raisin::Encoder::Form->deserialize($req);

        is_deeply $data, $c->{expected};
    }
};

done_testing;
