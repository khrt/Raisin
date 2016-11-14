
use strict;
use warnings;

use JSON;
use Test::More;
use Types::Standard qw/HashRef ArrayRef Str/;

use Raisin;
use Raisin::Param;
use Raisin::Plugin::Swagger;
use Raisin::Routes;
use Raisin::Routes::Endpoint;

my @INFO_CASES = (
    {
        settings => {},
        expected => {
            title => 'API',
            version => '0.0.1',
        },
    },
    {
        settings => {
            title => 'Test API',
            version => 'Test v0.0.1',
            description => 'Test API description',
            terms_of_service => '?',
            contact => {
                email => 'rtkh@cpan.org',
                name => 'Artur Khabibullin',
                url => 'https://metacpan.org/author/RTKH',
            },
            license => {
                name => 'Perl license',
                url => 'http://dev.perl.org/licenses/',
            },
        },
        expected => {
            title => 'Test API',
            version => 'Test v0.0.1',
            description => 'Test API description',
            termsOfService => '?',
            contact => {
                email => 'rtkh@cpan.org',
                name => 'Artur Khabibullin',
                url => 'https://metacpan.org/author/RTKH',
            },
            license => {
                name => 'Perl license',
                url => 'http://dev.perl.org/licenses/',
            },
        },
    }
);

my @PARAMETERS_CASES = (
    {
        method => 'GET',
        params => [
            Raisin::Param->new(
                named => 1,
                type  => 'required',
                spec  => { name => 'str', type => Str, default => 'def' },
            )
        ],
        expected => [
            {
                default => 'def',
                description => '',
                in => 'path',
                name => 'str',
                required => JSON::true,
                type => 'string',
            }
        ]
    },
    {
        method => 'GET',
        params => [
            Raisin::Param->new(
                named => 0,
                type  => 'required',
                spec  => { name => 'str', type => Str, default => 'def' },
            )
        ],
        expected => [
            {
                default => 'def',
                description => '',
                in => 'query',
                name => 'str',
                required => JSON::true,
                type => 'string',
            }
        ]
    },
    {
        method => 'POST',
        params => [
            Raisin::Param->new(
                named => 0,
                type  => 'required',
                spec  => { name => 'str', type => Str, default => 'def' },
            )
        ],
        expected => [
            {
                default => 'def',
                description => '',
                in => 'formData',
                name => 'str',
                required => JSON::true,
                type => 'string',
            }
        ]
    },
    {
        method => 'POST',
        params => [
            Raisin::Param->new(
                named => 0,
                type  => 'required',
                spec  => { name => 'str', type => Str, default => 'def', in => 'header' },
            )
        ],
        expected => [
            {
                default => 'def',
                description => '',
                in => 'header',
                name => 'str',
                required => JSON::true,
                type => 'string',
            }
        ]
    },
    # Nested
    {
        method => 'POST',
        params => [
            Raisin::Param->new(
                named => 0,
                type  => 'required',
                spec  => {
                    name => 'person',
                    type => HashRef,
                    encloses => [
                        requires => {
                            name => 'name',
                            type => HashRef,
                            encloses => [
                                requires => { name => 'first_name', type => Str },
                                requires => { name => 'last_name',  type => Str }
                            ],
                        },
                        optional => { name => 'city', type => Str },
                    ],
                },
            )
        ],
        expected => [
            {
                description => '',
                in => 'body',
                name => 'person',
                required => JSON::true,
                schema => {
                    '$ref' => '#/definitions/Person',
                },
            }
        ]
    },
);

{
    package Entity::Simple;

    use Raisin::Entity;
    use Types::Standard qw/Any Str/;

    expose 'id', type => Any;
    expose 'name', as => 'alias', type => Str;

    package Entity::Nested;

    use Raisin::Entity;

    expose 'id';
    expose 'simple', using => 'Entity::Simple';
}

sub _make_object {
    my (%args) = @_;

    my $caller = caller;
    my $app = Raisin->new(caller => $caller);

    my $module = Raisin::Plugin::Swagger->new($app);
    $module->build(%args);

    $module;
}
my $z = _make_object();

subtest '_info_object' => sub {
    # + _contact_object, _license_object
    for my $case (@INFO_CASES) {
        $z->app->api_version($case->{settings}{version})
            if $case->{settings}{version};

        swagger_setup(%{ $case->{settings} });
        is_deeply Raisin::Plugin::Swagger::_info_object($z->app), $case->{expected};
    }
};

subtest '_response_object' => sub {
    my $r = Raisin::Routes::Endpoint->new(
            api_format => 'json',
            desc => 'Test endpoint',
            entity => 'Entity::Simple',
            method => 'GET',
            path => '/user/:id',
        );
    my $resp = Raisin::Plugin::Swagger::_response_object($r);

    my %expected = (
        200 => {
            description => 'Test endpoint',
            schema => {
                '$ref' => sprintf('#/definitions/%s', Raisin::Plugin::Swagger::_name_for_object($r->entity)),
            }
        },
    );

    is_deeply $resp, \%expected, 'response object is correct';
};

subtest '_parameters_object' => sub {
    for my $case (@PARAMETERS_CASES) {
        my $obj = Raisin::Plugin::Swagger::_parameters_object(
            $case->{method},
            $case->{params}
        );

        for my $o (@$obj) {
            $o->{schema}{'$ref'} =~ s/([^-])-.*/$1/ if $o->{schema};
        }

        is_deeply $obj, $case->{expected},
            "$case->{method} $case->{expected}[0]{in} $case->{expected}[0]{name}";
    }
};

subtest '_definitions_object' => sub {
    my $r = Raisin::Routes->new;
    $r->add(
        code => sub {1},
        api_format => 'json',
        desc => 'Test endpoint',
        entity => 'Entity::Nested',
        method => 'POST',
        params =>  [
            requires => {
                name => 'person',
                type => HashRef,
                encloses => [
                    requires => {
                        name => 'name',
                        type => HashRef,
                        encloses => [
                            requires => { name => 'first_name', type => Str },
                            requires => { name => 'last_name',  type => Str }
                        ],
                    },
                    optional => { name => 'city', type => Str },
                ],
            },
        ],
        path => '/api',
    );

    my $def = Raisin::Plugin::Swagger::_definitions_object($r->routes);
    my %names_map = map { (split '-', $_)[0] => $_ } keys %$def;

    my %expected = (
        'Name' => {
            'properties' => {
                'first_name' => { 'type' => 'string' },
                'last_name' => { 'type' => 'string' }
            },
            'required' => ['first_name', 'last_name'],
            'type' => 'object'
        },
        'Person' => {
            'properties' => {
                'city' => { 'type' => 'string' },
                'name' => {
                    '$ref' => "#/definitions/$names_map{Name}"
                }
            },
            'required' => ['name'],
            'type' => 'object'
        }
    );

    for my $key (qw/Name Person/) {
        is_deeply $def->{ $names_map{ $key } }, $expected{ $key }, "$key schema";
    }
};

subtest '_schema_object' => sub {
    my $p0 = $PARAMETERS_CASES[-1]->{params}[0];
    my $p1 = $PARAMETERS_CASES[-1]->{params}[0]->enclosed->[0];

    my $schema0 = Raisin::Plugin::Swagger::_schema_object($p0);
    my $schema1 = Raisin::Plugin::Swagger::_schema_object($p1);

    #Person:
    #  type: object
    #  required:
    #      - name
    #  properties:
    #      name:
    #          $ref: '#/definitions/Name'
    #      city:
    #          type: string
    #

    #Name:
    #  type: object
    #  required:
    #      - first_name
    #      - last_name
    #  properties:
    #      first_name:
    #          type: string
    #      last_name:
    #          type: string

    my $schema0_expected = {
        [keys(%$schema0)]->[0] => {
            type => 'object',
            required => [qw/name/],
            properties => {
                name => { '$ref' => "#/definitions/${ \[keys(%$schema1)]->[0] }" },
                city => { type  => 'string' },
            },
        },
    };
    my $schema1_expected = {
        [keys(%$schema1)]->[0] => {
            type => 'object',
            required => [qw/first_name last_name/],
            properties => {
                first_name => { type => 'string' },
                last_name => { type => 'string' },
            },
        }
    };

    is_deeply $schema0, $schema0_expected, 'schema0 is correct';
    is_deeply $schema1, $schema1_expected, 'schema1 is correct';

    is [split '/', $schema0->{ [keys(%$schema0)]->[0] }{properties}{name}{'$ref'}]->[-1],
        [keys(%$schema1)]->[0], 'fingerprints are correct';
};

subtest '_operation_object' => sub {
    plan skip_all => 'TODO';

#    my $rn = Raisin::Routes::Endpoint->new(
#            api_format => 'json',
#            desc => 'Test endpoint',
#            entity => 'Entity::Nested',
#            method => 'GET',
#            path => '/user/:id',
#        );
#
#    my $rno = Raisin::Plugin::Swagger::_operation_object($rn);
#    use DDP;
#    p $rno;
};

subtest '_paths_object' => sub {
    plan skip_all => 'TODO';
};

subtest '_tags_object' => sub {
    plan skip_all => 'TODO';
};

subtest '_spec20' => sub {
    plan skip_all => 'TODO';
};

done_testing;
