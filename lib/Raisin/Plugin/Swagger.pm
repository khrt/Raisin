package Raisin::Plugin::Swagger;

use strict;
use warnings;

use parent 'Raisin::Plugin';

use JSON 'encode_json';

my %SETTINGS;
my %DEFAULTS;

sub build {
    my ($self, %args) = @_;

    # Enable CORS
    if ($args{enable} && lc($args{enable}) eq 'cors') {
        $self->app->add_middleware(
            'CrossOrigin',
            origins => '*',
            methods => [qw(GET HEAD POST DELETE PUT PATCH OPTIONS)],
            headers => [qw(api_key authorization content-type accept)]
        );
    }

    if ($args{version} && $args{version} == 1.2) {
        $self->register(
            swagger_build_spec => sub { $self->_spec_12 }
        );
        $self->{swagger_version} = '1.0';
    }
    else {
        $self->register(
            swagger_build_spec => sub { $self->_spec_20 },
            swagger_setup => sub { %SETTINGS = @_ },
        );
        $self->{swagger_version} = '2.0';
    }
}

sub _contact_object {
    my $contact = shift;
    my %obj;
    for (qw(name url email)) {
        $obj{$_} = $contact->{$_} if $contact->{$_};
    }
    \%obj;
}

sub _license_object {
    my $license = shift;
    my %obj = (
        name => $license->{name}, #R
    );
    $obj{url} = $license->{url} if $license->{url};
    \%obj;
}

sub _info_object {
    my $self = shift;

    my %obj = (
        title => $SETTINGS{title} || 'API', #R
        version => $self->app->api_version || '0.0.1', #R
    );

    $obj{description} = $SETTINGS{description} if $SETTINGS{description};
    $obj{termsOfService} = $SETTINGS{terms_of_service} if $SETTINGS{terms_of_service};

    $obj{contact} = _contact_object($SETTINGS{contact}) if keys %{ $SETTINGS{contact} };
    $obj{license} = _license_object($SETTINGS{license}) if keys %{ $SETTINGS{license} };

    \%obj;
}

sub _parameters_object {
    my ($method, $pp) = @_;

    my @obj;

    for my $p (@$pp) {
        my $position = do {
            if    ($p->named)              {'path'}
            elsif ($method =~ /post|put/i) {'formData'}
            #elsif ($method =~ /post|put/i) {'body'}
            #elsif ()                       {'header'}
            else                           {'query'}
        };

        my ($type, $format) = do {
            if    ($p->type->name =~ /int/i)            { 'integer', 'int32' }
            elsif ($p->type->name =~ /long/i)           { 'integer', 'int64' }
            elsif ($p->type->name =~ /num|float|real/i) { 'number',  'float' }
            elsif ($p->type->name =~ /double/i)         { 'number',  'double' }
            elsif ($p->type->name =~ /str/i)            { 'string',  undef }
            elsif ($p->type->name =~ /byte/i)           { 'string',  'byte' }
            elsif ($p->type->name =~ /bool/i)           { 'boolean', undef }
            elsif ($p->type->name =~ /datetime/i)       { 'string',  'date-time' }
            elsif ($p->type->name =~ /date/i)           { 'string',  'date' }
            # fallback
            else { 'string', undef }
            # TODO string, number, integer, boolean, array, file
        };

        my %param = (
            description => $p->desc || "",
            in          => $position, #R
            name        => $p->name, #R
            required    => $p->required ? JSON::true : JSON::false,
            type        => $type, #R
        );
        $param{default} = $p->default if defined $p->default;
        $param{format} = $format if $format;

        #if ($type eq 'array') {
        #    $param{items} = ''; #R if is array
        #    $param{collectionFormat} = ''; # if is array
        #}

        push @obj, \%param;
    }

    \@obj;
}

sub _operation_object {
    my $r = shift;

    my $path = $r->path;
    $path =~ tr#/:#_#;
    my $operation_id = lc($r->method) . $path;

    my %obj = (
        tags => $r->tags,
        summary => $r->summary || "",
        description => $r->desc || "",
        #externalDocs => '',
        operationId => $operation_id,
        consumes => $DEFAULTS{consumes},
        produces => $DEFAULTS{produces},
        # TODO:
        responses => { #R
            500 => { #R
                description => 'server exception', #R
                #schema => '',
                #headers => '',
                #examples => '',
            },
        },
        #schemes => [''],
        #deprecated => 'false', # TODO
        #security => '',
    );

    my $params = _parameters_object($r->method, $r->params);

    $obj{parameters} = $params if scalar @$params;

    \%obj;
}

sub _paths_object {
    my $self = shift;

    my %obj;

    for my $r (sort { $a->path cmp $b->path } @{ $self->app->routes->routes }) {
        my $path = $r->path;
        $path =~ s#:([^/]+)#{$1}#msix;

        $obj{ $path }{ lc($r->method) } = _operation_object($r);
    }

    \%obj;
}

sub _tags_object  {
    my $self = shift;

    my %tags;
    for my $r (@{ $self->app->routes->routes }) {
        $tags{ $_ }++ for @{ $r->tags };
    }

    my @tags;
    for my $t (keys %tags) {
        my $tag = {
            name => $t, #R
            description => $self->app->resource_desc($t),
            #externalDocs => {
            #    description => '',
            #    url => '', #R
            #},
        };
        push @tags, $tag;
    }

    \@tags;
}

sub _spec_20 {
    my $self = shift;
    return 1 if $self->{built};
    my $req = $self->app->req;

    my @content_types = $self->app->api_format
        ? $self->app->api_format
        : qw(application/yaml application/json);

    my $base_path = $req->base->as_string;
    $base_path =~ s#http(?:s?)://[^/]+##msix;

    $DEFAULTS{consumes} = \@content_types;
    $DEFAULTS{produces} = \@content_types;

    my %spec = (
        swagger  => '2.0',
        info     => $self->_info_object,
        host     => $req->env->{HTTP_HOST},
        basePath => $base_path,
        schemes  => [$req->scheme],
        consumes => \@content_types,
        produces => \@content_types,
        paths    => $self->_paths_object, #R
        #definitions => undef,
        #parameters => undef,
        #responses => undef,
        #securityDefinitions => undef,
        #security => undef,
        tags => $self->_tags_object,
        #externalDocs => '', # TODO
    );

    $self->app->add_route(
        method => 'GET',
        path => '/api-docs',
        code => sub {
            #res->content_type('application/json');
            encode_json(\%spec);
        }
    );

    $self->{built} = 1;
}

# NOTE: Deprecated
sub _spec_12 {
    my $self = shift;
    return 1 if $self->{built};

    my $app = $self->app;

    my %apis;

    # Prepare API data
    for my $r (@{ $app->routes->routes }) {
        my @params;
        for my $p (@{ $r->params }) {
            my $param_type = do {
                if    ($p->named)                 {'path'}
                elsif ($r->method =~ /post|put/i) {'form'}
                else                              {'query'}
            };

            push @params,
                {
                    allowMultiple => JSON::true,
                    defaultValue  => $p->default // JSON::false,
                    description   => $p->desc || '~',
                    format        => $p->type->display_name,
                    name          => $p->name,
                    paramType     => $param_type,
                    required      => $p->required ? JSON::true : JSON::false,
                    type          => $p->type->name,
                };
        }

        my $path = $r->path;

        # :id -> {id}
        $path =~ s#:([^/]+)#{$1}#msxg;

        # look for namespace
        my ($ns) = $path =~ m#^(/[^/]+)#;

        # -> [ $ns => { ... } ]
        push @{ $apis{$ns} },
            {
                path => $path,
                description => '',
                operations  => [{
                    method     => $r->method,
                    nickname   => $r->method . '_' . $path,
                    notes      => '',
                    parameters => \@params,
                    summary    => $r->desc,
                    type       => '',
                }],
            };
    }

    my %template = (
        swaggerVersion => '1.2',
    );
    $template{apiVersion} = $self->app->api_version if $self->app->api_version;

    # Prepare index
    my %index = (%template);
    for my $ns (keys %apis) {
        my $desc = $app->resource_desc($ns) || "Operations about ${ \( $ns =~ m#/(.+)# ) }";

        my $api = {
            path => $ns,
            description => $desc,
        };

        push @{ $index{apis} }, $api;
    }

    $app->add_route(
        method => 'GET',
        path => '/api-docs',
        code => sub {
            res->content_type('application/json');
            encode_json(\%index);
        }
    );

    for my $ns (keys %apis) {
        my $base_path = $app->req ? $app->req->base->as_string : '';
        $base_path =~ s#/$##msx;

        my @content_type = do {
            if ($app->api_format) {
                ($app->api_format)
            }
            else {
                qw(application/yaml application/json);
            }
        };

        my %description = (
            %template,
            apis => $apis{$ns},
            basePath => $base_path,
            produces => [@content_type],
            resourcePath => $ns,
        );

        $app->add_route(
            method => 'GET',
            path => "/api-docs${ns}",
            code => sub {
                res->content_type('application/json');
                encode_json(\%description);
            }
        );
    }

    $self->{built} = 1;
}

1;

__END__

=head1 NAME

Raisin::Plugin::Swagger - Generate API documentation.

=head1 SYNOPSIS

    plugin 'Swagger';

=head1 DESCRIPTION

Generate L<Swagger|https://github.com/wordnik/swagger-core>
compatible API documentaions.

Provides documentation in Swagger compatible format by C</api-docs> URL.
You can use this url in L<Swagger UI|http://swagger.wordnik.com/>.

=head1 CORS

Cross-origin resource sharing

    plugin 'Swagger', enable => 'CORS';

=head1 VERSION

Which Swagger version to use. By default 2.0 is used, also 1.2 available.

    plugin 'Swagger', version => 1.2;

=head1 FUNCTIONS

=head3 swagger_setup

    swagger_setup(
        title => 'BatAPI',
        description => 'Simple BatAPI.',

        contact => {
            name => 'Bruce Wayne',
            url => 'http://wayne.enterprises',
            email => 'bruce@batman.com',
        },

        license => {
            name => 'Barman license',
            url => 'http://wayne.enterprises/licenses/',
        },
    );

title, description, terms_of_service

contact: name, url, email

license: name, url

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
