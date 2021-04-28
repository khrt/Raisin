
use strict;
use warnings;

use HTTP::Message::PSGI;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Request;
use Plack::Test;
use Test::More;

use Raisin::Encoder;
use Raisin::Decoder;
use Raisin::Middleware::Formatter;

{
    no strict 'refs';
    *Raisin::log = sub { note(sprintf $_[1], @_[2 .. $#_]) };
}

subtest 'call' => sub {
    my @CASES = (
        # text to data
        {
            req => POST('/', Content_Type => 'application/json; charset=utf-8', Content => '{"json":true}'),
            params => { default_format => 'yaml', },
            expected => 'json',
            message => 'content: json, default_format: yaml',
        },
        {
            req => POST('/', Content_Type => 'application/json', Content => '{"json":true}'),
            params => { default_format => 'yaml', },
            expected => 'json',
            message => 'content: json, default_format: yaml',
        },
        {
            req => POST('/', Content_Type => 'application/yaml', Content => "---\nkey: val\n"),
            params => { default_format => 'yaml', },
            expected => 'yaml',
            message => 'content: yaml, default_format: yaml',
        },
        {
            req => POST('/', Content_Type => 'application/xml', Content => "<xml/>"),
            params => { default_format => 'yaml', },
            expected => undef,
            message => 'content: xml, default_format: yaml',
        },

        # data to text
        {
            req => GET('/path', Accept => '*/*'),
            params => { default_format => 'yaml', },
            expected => 'yaml',
            message => 'accept: any',
        },

        {
            req => GET('/path.json', Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'),
            expected => 'json',
            message => 'accept: any, ext: json',
        },

        {
            req => GET('/path.yaml'),
            expected => 'yaml',
            message => 'ext: yaml',
        },

        {
            req => GET('/path', Accept => 'text/html,application/json'),
            expected => 'json',
            message => 'accept: json',
        },

        {
            req => GET('/path'),
            params => { default_format => 'yaml', },
            expected => 'yaml',
            message => 'default format: yaml',
        },
    );

    for my $c (@CASES) {
        my $app = builder {
            enable '+Raisin::Middleware::Formatter',
                encoder => Raisin::Encoder->new,
                decoder => Raisin::Decoder->new,
                %{ $c->{params} || {} };

            sub {
                my ($env) = @_;
                my $env_key = sprintf 'raisinx.%s',
                    $c->{req}->method eq 'POST' ? 'decoder' : 'encoder';
                return [200, ['X-RET' => $env->{$env_key}], []];
            };
        };

        test_psgi $app, sub {
            my $cb = shift;

            my $res = $cb->($c->{req});
            is $res->header('x-ret'), $c->{expected}, $c->{message};
        };
    }
};

subtest 'negotiate_format' => sub {
    my @CASES = (
        # extension
        {
            env => GET('/path.json')->to_psgi,
            expected => 'json',
            message => 'ext: json',
        },
        # extension, accept set
        {
            env => GET('/path.json', Accept => 'application/x-yaml')->to_psgi,
            expected => 'json',
            message => 'ext: json, accept: yaml',
        },
        # extension, not supported
        {
            env => GET('/path.xml')->to_psgi,
            expected => undef,
            message => 'ext: not supported',
        },

        # accept
        {
            env => GET('/path', Accept => 'application/x-yaml')->to_psgi,
            expected => 'yaml',
            message => 'accept: yaml',
        },
        # accept, */*
        {
            env => GET('/path', Accept => '*/*')->to_psgi,
            params => { default_format => 'yaml' },
            expected => 'yaml',
            message => 'accept: *',
        },
        # accept, not supported
        {
            env => GET('/path', Accept => 'application/xml')->to_psgi,
            expected => undef,
            message => 'accept: not supported',
        },

        # default format + accept, not supported
        {
            env => GET('/path', Accept => 'application/xml')->to_psgi,
            params => { default_format => 'yaml' },
            expected => undef,
            message => 'default_format + accept: not supported',
        },
        # default format
        {
            env => GET('/path')->to_psgi,
            params => { default_format => 'yaml' },
            expected => 'yaml',
            message => 'default format',
        },

        # format + extension
        {
            env => GET('/path.json')->to_psgi,
            params => { default_format => 'json', format => 'json' },
            expected => 'json',
            message => 'format: json, ext: json',
        },
        # format + accept
        {
            env => GET('/path', Accept => 'application/json')->to_psgi,
            params => { default_format => 'json', format => 'json' },
            expected => 'json',
            message => 'format: json, accept: json',
        },
        # format + extension, not supported
        {
            env => GET('/path.json')->to_psgi,
            params => { default_format => 'yaml', format => 'yaml' },
            expected => undef,
            message => 'format: yaml, ext: json, not supported',
        },
        # format + accept
        {
            env => GET('/path', Accept => 'application/json')->to_psgi,
            params => { default_format => 'yaml', format => 'yaml' },
            expected => undef,
            message => 'format: yaml, accept: json, not supported',
        },

        # accept, multi
        {
            env => GET('/path', Accept => 'text/html,application/x-yaml;q=0.9,application/json;q=0.8,*/*;q=0.7')->to_psgi,
            expected => 'yaml',
            message => 'accept: yaml, multi',
        },
    );

    for my $c (@CASES) {
        my $fmt = Raisin::Middleware::Formatter->new(
            %{ $c->{params} || {} },
            encoder => Raisin::Encoder->new,
        );
        my $req = Plack::Request->new($c->{env});

        is $fmt->negotiate_format($req), $c->{expected}, $c->{message};
    }
};

subtest 'format_from_extension' => sub {
    my @CASES = (
        { ext => '.yaml', expected => 'yaml' },
        { ext => '.json', expected => 'json' },
        { ext => '.txt',  expected => 'text' },

        { ext => '.text', expected => undef },
        { ext => '.xml',  expected => undef },

        { ext => '', expected => undef },
    );

    for my $c (@CASES) {
        my $fmt = Raisin::Middleware::Formatter->new(
            encoder => Raisin::Encoder->new
        );

        is $fmt->format_from_extension($c->{ext}), $c->{expected}, $c->{ext};
    }
};

subtest 'format_from_header' => sub {
    my $DEFAULT_FORMAT = 'yaml';

    my @CASES = (
        {
            header => 'application/vnd.raisin+x-yaml,application/json;q=0.9,*/*;q=0.8',
            expected => ['yaml', 'json', $DEFAULT_FORMAT],
        },
        {
            header => 'application/json,application/x-yaml;q=0.9,*/*;q=0.8',
            expected => ['json', 'yaml', $DEFAULT_FORMAT],
        },

        {
            header => 'application/json,application/x-yaml',
            expected => [qw/json yaml/],
        },
        {
            header => 'application/x-yaml,application/json',
            expected => [qw/yaml json/],
        },

        {
            header => 'application/x-yaml,text/html',
            expected => [qw/yaml/],
        },
        {
            header => 'text/html,application/x-yaml',
            expected => [qw/yaml/],
        },

        {
            header => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            expected => [$DEFAULT_FORMAT],
        },
        {
            header => '*/*',
            expected => [$DEFAULT_FORMAT],
        },

        {
            header => 'application/json; charset=utf-8; foo=bar',
            expected => [qw/json/],
        },

        {
            header => '',
            expected => [qw//],
        },
    );

    for my $c (@CASES) {
        my $fmt = Raisin::Middleware::Formatter->new(
            encoder => Raisin::Encoder->new
        );

        my @h = $fmt->format_from_header($c->{header}, $DEFAULT_FORMAT);
        is_deeply \@h, $c->{expected}, join('>', @{ $c->{expected} }) || 'NONE';
    }
};

subtest '_path_has_extension' => sub {
    my @CASES = (
        {
            path => '/a/b/c.exe',
            expected => '.exe',
            message => 'extension',
        },
        {
            path => '/a/b.at/c',
            expected => '',
            message => 'no extension',
        },
        {
            path => '/',
            expected => '',
            message => 'slash',
        },
        {
            path => '',
            expected => '',
            message => 'empty',
        },
    );

    for my $c (@CASES) {
        is Raisin::Middleware::Formatter::_path_has_extension($c->{path}), $c->{expected}, $c->{message};
    }
};

done_testing;
