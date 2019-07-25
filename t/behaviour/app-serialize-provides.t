
use strict;
use warnings;

use Data::Dumper;
use HTTP::Request::Common qw(GET);
use Plack::Test;
use Test::More;
use YAML;
use JSON::MaybeXS;

use Raisin::API;
use Types::Standard qw(Int Str);

my $BINARY_DATA = "DUMMY\{0}BINARY\{0}BLOB\{0}";

{
    # no-op encoder that responds to certain content types
    package Test::Encoder::Blob;
    sub detectable_by { [qw(application/blob blob)] }
    sub content_type  { 'x-application/blob' }

    sub serialize   { $_[1] }
    sub deserialize { $_[1] }

    # Appease Plack::Util->load_class
    $INC{'Test/Encoder/Blob.pm'} = 1;
}

my $app = eval {
    resource blob => sub {
        produces [ 'blob' ];
        get sub { $BINARY_DATA };
    };
    register_encoder('blob' => 'Test::Encoder::Blob');
    run;
};

{
    no strict 'refs';
    no warnings qw(once redefine);
    *Raisin::log = sub { note(sprintf $_[1], @_[2 .. $#_]) };
}

BAIL_OUT $@ if $@;

subtest 'via Accept' => sub {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/blob', Accept => 'application/blob');

        is $res->code, 200, 'status';
        is $res->content, $BINARY_DATA, 'content';
        is $res->content_type, 'x-application/blob', 'content type';
    };
};

subtest 'via Accept */*' => sub {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/blob', Accept => 'application/xml, */*');

        is $res->code, 200, 'status';
        is $res->content, $BINARY_DATA, 'content';
        is $res->content_type, 'x-application/blob', 'content type';
    };
};

subtest 'via Extension' => sub {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/blob.blob');

        is $res->code, 200, 'status';
        is $res->content, $BINARY_DATA, 'content';
        is $res->content_type, 'x-application/blob', 'content type';
    };
};


subtest 'unacceptable' => sub {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/blob', Accept => 'application/json');

        is $res->code, 406, 'status';
    };
};


done_testing;
