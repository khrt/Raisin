package Raisin::Plugin::Swagger;

use strict;
use warnings;

use parent 'Raisin::Plugin';

use Data::Dumper;
use Digest::MD5 qw/md5_hex/;
use JSON qw/encode_json/;

my %SETTINGS;
my %DEFAULTS;

my $HTTP_OK = 200;

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

    $self->register(
        swagger_build_spec => sub { $self->_spec_20 },
        swagger_setup => sub { %SETTINGS = @_ },
    );
    $self->{swagger_version} = '2.0';
}

sub _spec_20 {
    my $self = shift;
    return 1 if $self->{built};

    my $app = $self->app;
    my $req = $app->req;
    my $routes = $app->routes->routes;

    my @content_types = $app->api_format
        ? $app->api_format
        : qw(application/yaml application/json);

    my $base_path = $req->base->as_string;
    $base_path =~ s#http(?:s?)://[^/]+##msix;

    $DEFAULTS{consumes} = \@content_types;
    $DEFAULTS{produces} = \@content_types;

    my %spec = (
        swagger  => '2.0',
        info     => _info_object($app),
        host     => $req->env->{SERVER_NAME} || $req->env->{HTTP_HOST},
        basePath => $base_path,
        schemes  => [$req->scheme],
        consumes => \@content_types,
        produces => \@content_types,
        paths    => _paths_object($routes),
        definitions => _definitions_object($routes),
        #parameters => undef,
        #responses => undef,
        #securityDefinitions => undef,
        #security => undef,
        tags => _tags_object($self->app),
        #externalDocs => '',
    );

    # routes
    $self->app->add_route(
        method => 'GET',
        path => '/swagger',
        code => sub { \%spec }
    );

    # mark as built
    $self->{built} = 1;

    \%spec;
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
        name => $license->{name},
    );
    $obj{url} = $license->{url} if $license->{url};
    \%obj;
}

sub _info_object {
    my $app = shift;

    my %obj = (
        title => $SETTINGS{title} || 'API',
        version => $app->api_version || '0.0.1',
    );

    $obj{description} = $SETTINGS{description} if $SETTINGS{description};
    $obj{termsOfService} = $SETTINGS{terms_of_service} if $SETTINGS{terms_of_service};

    $obj{contact} = _contact_object($SETTINGS{contact}) if keys %{ $SETTINGS{contact} };
    $obj{license} = _license_object($SETTINGS{license}) if keys %{ $SETTINGS{license} };

    \%obj;
}

sub _paths_object {
    my $routes = shift;

    my %obj;
    for my $r (sort { $a->path cmp $b->path } @$routes) {
        next if lc($r->method) eq 'options';

        my $path = $r->path;
        $path =~ s#:([^/]+)#{$1}#msix;

        $obj{ $path }{ lc($r->method) } = _operation_object($r);
    }

    \%obj;
}

sub _operation_object {
    my $r = shift;

    my $path = $r->path;
    $path =~ tr#/:#_#;
    my $operation_id = lc($r->method) . $path;

    my %obj = (
        consumes => $DEFAULTS{consumes},
        #deprecated => 'false',
        description => $r->desc || '',
        #externalDocs => '',
        operationId => $operation_id,
        produces => $DEFAULTS{produces},
        responses => {
            default => {
                description => 'Unexpected error',
                #examples => '',
                #headers => '',
                #schema => '',
            },
            # Adds a response object from route's entity if it exists
            %{ _response_object($r) },
        },
        #schemes => [],
        #security => '',
        summary => $r->summary || '',
        tags => $r->tags,
    );

    my $params = _parameters_object($r->method, $r->params);
    $obj{parameters} = $params if scalar @$params;

    \%obj;
}

sub _response_object {
    my $r = shift;
    return {} unless $r->entity;

    my $name = $r->entity;

    my %obj = (
        $HTTP_OK => {
            description => $r->desc || $r->summary || '',
            schema => {
                '$ref' => sprintf('#/definitions/%s', _name_for_object($name)),
            }
        },
    );

    \%obj;
}

sub _parameters_object {
    my ($method, $pp) = @_;

    my @obj;
    for my $p (@$pp) {
        my ($type) = _param_type($p->type);

        # Available: query, header, path, formData or body
        my $location = do {
            if    ($p->in)                       { $p->in }
            elsif ($p->named)                    { 'path' }
            elsif ($type eq 'object')            { 'body' }
            elsif ($method =~ /patch|post|put/i) { 'formData' }
            else                                 { 'query' }
        };

        my $ptype = _param_type_object($p);
        if ($p->type->name eq 'HashRef') {
            $ptype->{schema}{'$ref'} = delete $ptype->{'$ref'};
        }

        my %param = (
            description => $p->desc || '',
            in          => $location,
            name        => $p->name,
            required    => $p->required ? JSON::true : JSON::false,
            %$ptype,
        );
        $param{default} = $p->default if defined $p->default;


        push @obj, \%param;
    }

    \@obj;
}

sub _definitions_object {
    my $routes = shift;

    my @objects;
    for my $r (@$routes) {
        if ($r->entity) {
            push @objects, $r->entity;
        }

        my @pp = @{ $r->params };
        while (my $p = pop @pp) {
            next if $p->type->name ne 'HashRef';

            push @pp, @{ $p->enclosed };
            push @objects, $p;
        }
    }

    my %definitions = map { %{ _schema_object($_) } } @objects;
    \%definitions;
}

sub _schema_object {
    my $p = shift;
    return if $p->type->name ne 'HashRef';

    my (@required, %properties);

    for my $pp (@{ $p->enclosed }) {
        $properties{ $pp->display_name } = _param_type_object($pp);

        push @required, $pp->display_name if $pp->required;
    }

    my %object = (
        _name_for_object($p) => {
            type => 'object',
            required => \@required,
            properties => \%properties,
        }
    );

    \%object;
}

sub _tags_object  {
    my $app = shift;

    my %tags;
    for my $r (@{ $app->routes->routes }) {
        $tags{ $_ }++ for @{ $r->tags };
    }

    my @tags;
    for my $t (keys %tags) {
        my $tag = {
            name => $t,
            description => $app->resource_desc($t),
            #externalDocs => {
            #    description => '',
            #    url => '', #R
            #},
        };
        push @tags, $tag;
    }

    \@tags;
}

sub _param_type_object {
    my $p = shift;

    my %item;

    if ($p->type->name eq 'HashRef') {
        $item{'$ref'} = sprintf('#/definitions/%s', _name_for_object($p));
    }
    elsif ($p->type->display_name =~ /^ArrayRef/) {
        $item{type} = 'array';

        my ($type, $format) = _param_type($p->type->type_parameter);
        if ($type eq 'object') {
            my $ref = do {
                if   ($p->can('using') && $p->using) { $p->using }
                else { $p }
            };

            $item{items}{'$ref'} = sprintf('#/definitions/%s', _name_for_object($ref));
        }
        else {
            $item{type} = $type;
            $item{format} = $format if $format;
            $item{description} = $p->desc if $p->desc;
        }
    }
    else {
        my ($type, $format) = _param_type($p->type);
        $item{type} = $type;
        $item{format} = $format if $format;
        $item{description} = $p->desc if $p->desc;
    }

    \%item;
}

sub _param_type {
    my $t = shift;

    if    ($t->name =~ /int/i)            { 'integer', 'int32' }
    elsif ($t->name =~ /long/i)           { 'integer', 'int64' }
    elsif ($t->name =~ /num|float|real/i) { 'number',  'float' }
    elsif ($t->name =~ /double/i)         { 'number',  'double' }
    elsif ($t->name =~ /str/i)            { 'string',  undef }
    elsif ($t->name =~ /byte/i)           { 'string',  'byte' }
    elsif ($t->name =~ /bool/i)           { 'boolean', undef }
    elsif ($t->name =~ /datetime/i)       { 'string',  'date-time' }
    elsif ($t->name =~ /date/i)           { 'string',  'date' }
    elsif ($t->name =~ /password/i)       { 'string',  'password' }
    elsif ($t->name =~ /hashref/i)        { 'object',  undef }
    else {
        if   ($t->display_name =~ /ArrayRef/) { 'array',  undef }
        else                                  { 'string', undef }    # fallback
    }
}

sub _name_for_object {
    my $obj = shift;

    local $Data::Dumper::Deparse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Maxdepth = 2;
    local $Data::Dumper::Purity = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;

    my $fingerprint = md5_hex(Data::Dumper->Dump([$obj], [qw/obj/]));

    sprintf '%s-%s', ucfirst($obj->name), uc(substr($fingerprint, 0, 10));
}

1;

__END__

=head1 NAME

Raisin::Plugin::Swagger - Generate API documentation.

=head1 SYNOPSIS

    plugin 'Swagger';

=head1 DESCRIPTION

Generates a L<Swagger|https://github.com/wordnik/swagger-core>
compatible API documentaion.

Provides a documentation by C</swagger.json> URL.
You can use this url in L<Swagger UI|http://petstore.swagger.io/>.

=head1 CORS

Enables a cross-origin resource sharing.

    plugin 'Swagger', enable => 'CORS';

=head1 VERSION

Supports only version 2.0 of Swagger.


=head1 FUNCTIONS

=head3 swagger_setup

The function configures base OpenAPI paramters, be aware it is not validating
and will be passed as is to OpenAPI client.

Properly configured section has following attributes:
B<title>, B<description>, B<terms_service>, B<contact> and B<license>.

B<Contact> has B<name>, B<url>, B<email>.

B<License> has B<name> and B<url>.

See an example below.

    swagger_setup(
        title => 'BatAPI',
        description => 'Simple BatAPI.',

        contact => {
            name => 'Bruce Wayne',
            url => 'http://wayne.enterprises',
            email => 'bruce@batman.com',
        },

        license => {
            name => 'Batman license',
            url => 'http://wayne.enterprises/licenses/',
        },
    );

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
