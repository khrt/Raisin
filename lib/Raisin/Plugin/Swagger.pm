#!perl
#PODNAME: Raisin::Plugin::Swagger
#ABSTRACT: Generates API description in Swagger 2/OpenAPI compatible format
# vim:ts=4:shiftwidth=4:expandtab:syntax=perl

use strict;
use warnings;

package Raisin::Plugin::Swagger;

use parent 'Raisin::Plugin';

use Carp 'croak';
use Data::Dumper;
use Digest::MD5 qw/md5_hex/;
use JSON::MaybeXS qw/encode_json/;
use List::Util qw/pairmap/;
use Scalar::Util qw(blessed);

my %DEFAULTS;
my %SETTINGS;

my $HTTP_OK = 200;

sub build {
    my $self = shift;

    $self->register(
        swagger_build_spec => sub { $self->_spec_20 },
        swagger_setup => sub { %SETTINGS = @_ },
        swagger_security => \&swagger_security,
    );

    1;
}

sub swagger_security {
    my %p = @_;

    croak 'Invalid `type`' unless grep { $p{type} eq $_ } qw/basic api_key oauth2/;

    my %security;

    if ($p{type} eq 'basic') {
        $security{ $p{name} } = {
            type => 'basic',
        };
    }
    elsif ($p{type} eq 'api_key') {
        croak 'Invalid `in`' unless grep { $p{in} eq $_ } qw/query header/;

        $security{ $p{name} } = {
            type => 'apiKey',
            name => $p{name},
            in => $p{in},
        };
    }
    elsif ($p{type} eq 'oauth2') {
        croak 'Invalid `flow`' unless grep { $p{flow} eq $_ } qw/implicit password application accessCode/;

        $security{ $p{name} } = {
            type => 'oauth2',
            flow => $p{flow},
            scopes => $p{scopes},
        };

        if (grep { $p{flow} eq $_ } qw/implicit accessCode/) {
            $security{ $p{name} }{authorizationUrl} = $p{authorization_url};
        }

        if (grep { $p{flow} eq $_ } qw/password application accessCode/) {
            $security{ $p{name} }{tokenUrl} = $p{token_url};
        }
    }

    $SETTINGS{security} = {
        %{ $SETTINGS{security} || {} },
        %security,
    };
}

sub _spec_20 {
    my $self = shift;
    return 1 if $self->{built};

    my $app = $self->app;
    my $req = $app->req;
    my $routes = $app->routes->routes;

    my @content_types = $app->format
        ? $app->format
        : qw(application/x-yaml application/json);

    my $base_path = $req->base->as_string;
    ### Respect proxied requests
    #   A proxy map is used to fill the "basePath" attribute.
    my $_base = $req->env->{HTTP_X_FORWARDED_SCRIPT_NAME} || q(/);
    $base_path =~ s#http(?:s?)://[^/]+/#$_base#msix;

    $DEFAULTS{consumes} = \@content_types;
    $DEFAULTS{produces} = \@content_types;

    my %spec = (
        swagger => '2.0',
        info => _info_object($app),
        ### Respect proxied requests
        #   The frontend hostname is used if set.
        host => $req->env->{HTTP_X_FORWARDED_HOST}
            || $req->env->{SERVER_NAME}
            || $req->env->{HTTP_HOST},
        basePath => $base_path,
        schemes => [$req->scheme],
        consumes => \@content_types,
        produces => \@content_types,
        paths => _paths_object($routes),
        definitions => _definitions_object($routes),
        #parameters => undef,
        #responses => undef,
        securityDefinitions => _security_definitions_object(),
        security => _security_object(),
        #tags => undef,
        #externalDocs => undef,
    );

    my $tags = _tags_object($self->app);
    if (scalar @$tags) {
        $spec{tags} = $tags;
    }

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

sub _security_object {
    my @obj = map { { $_->{name} => $_->{scopes} || [] } } values %{ $SETTINGS{security} };
    \@obj;
}

sub _security_definitions_object { $SETTINGS{security} || {} }

sub _paths_object {
    my $routes = shift;

    my %obj;
    for my $r (sort { $a->path cmp $b->path } @$routes) {
        next if lc($r->method) eq 'options';

        my $path = $r->path;
        $path =~ s#:([^/]+)#{$1}#msixg;

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
        produces => $r->produces || $DEFAULTS{produces},
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
        #security => {}, # TODO per operation permissions
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
        if (_type_name($p->type) =~ /^HashRef$/ ) {
            $ptype->{schema}{'$ref'} = delete $ptype->{'$ref'};
        }

        # If the type is an Enum, set type to string and give the enum values.
        if (_type_is_enum($p->type)) {
            $ptype->{type} = 'string';
            $ptype->{enum} = $p->type->values;
        }

        my %param = (
            description => $p->desc || '',
            in          => $location,
            name        => $p->name,
            required    => $p->required ? JSON::MaybeXS::true : JSON::MaybeXS::false,
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
            next unless _type_name($p->type) =~ /^HashRef$/;
            push @pp, @{ $p->enclosed || [] };
            push @objects, $p;
        }
    }

    my %definitions = map { %{ _schema_object($_) } }
                        _collect_nested_definitions(@objects);
    \%definitions;
}

sub _collect_nested_definitions {
    my @objects = @_;
    return () unless scalar @objects;

    my @nested;
    for my $obj (@objects) {
        if( $obj->can('enclosed') ) {
            for my $expose ( @{ $obj->enclosed || [] } ) {
                if (exists $expose->{'using'} ){
                    push @nested, $expose->{using};
                }
            }
        }
    }
    push @objects, _collect_nested_definitions(@nested);

    return @objects;
}


sub _schema_object {
    my $p = shift;
    return unless _type_name($p->type) =~ /^HashRef$/;

    my (@required, %properties);
    for my $pp (@{ $p->enclosed || [] }) {
        $properties{ _type_name($pp) } = _param_type_object($pp);

        push @required, _type_name($pp) if $pp->required;
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
        next unless $_;
        $tags{ $_ }++ for @{ $r->tags };
    }

    my @tags;
    for my $t (keys %tags) {
        my $tag = {
            name => $t,
            description => $app->resource_desc($t) || '',
            #externalDocs => {
            #    description => '',
            #    url => '', #R
            #},
        };
        push @tags, $tag;
    }

    \@tags;
}

# get the name of a type
sub _type_name {
    my $type = shift;
    if ($type && $type->can('display_name')) {
        return $type->display_name;
    }
    elsif ($type && $type->can('name')) {
        # fall back to name() (e.g. Moose types do not have display_name)
        return $type->name;
    }
    else {
        return "$type";
    }
}

sub _param_type_object {
    my $p = shift;
    my %item;

    my $tt = $p->type;


    if (_type_name($tt) =~ /^Maybe\[/) {
    $item{nullable} = JSON::MaybeXS::true;
        $tt = $tt->type_parameter;
    }

    if (_type_name($tt) =~ /^HashRef$/ ) {
        $item{'$ref'} = sprintf('#/definitions/%s', _name_for_object($p->can('using')?$p->using:$p));
    }
    elsif (_type_name($tt) =~ /^HashRef\[.*\]$/) {
        $item{'type'} = 'object';
        $item{'additionalProperties'} = {
                            '$ref' => sprintf('#/definitions/%s', _name_for_object($p->using))
                            };
    }
    elsif (_type_name($tt) =~ /^ArrayRef/) {
        $item{type} = 'array';

        my $type;
        my $format;

        # Loop down to find type beneath coercion.
        while (!defined $type) {
            if($tt->can('type_parameter')) {
                ($type, $format) = _param_type($tt->type_parameter);
            }
            else {
                ($type, $format) = ('object', '' );
            }
            $tt = $tt->parent if !defined $type;
        }

        if ($type eq 'object') {
            $item{items} = {}; # {} is the "any-type" schema.
            if ($p->can('using') && $p->using) {
                $item{items}{'$ref'} = sprintf('#/definitions/%s', _name_for_object($p->using));
            }
            elsif ($tt->can("type_parameter")) {
               my ($subscript_type, $subscript_format) = _param_type($tt->type_parameter);
               if (defined $subscript_type) {
                  $item{items}->{type}   = $subscript_type;
                  $item{items}->{format} = $subscript_format if defined $subscript_format;
               }
            }
        }
        else {
            $item{items}->{type} = $type;
            $item{items}->{format} = $format if $format;
            $item{description} = $p->desc if $p->desc;
        }
    }
    else {
        my ($type, $format) = _param_type($tt);
        $item{type} = $type;
        $item{format} = $format if $format;
        $item{description} = $p->desc if $p->desc;
    }
    \%item;
}

sub _param_type {
    my $t = shift;
    if ($t && $t->can('name')) {  # allow nested types as Str in ArrayRef[Str]
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
            if   (_type_name($t) =~ /ArrayRef/) { 'array',  undef }
            else                                  { 'object', undef }    # fallback
        }
    }
    else {
        { $t, undef }
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
    my $objname = ucfirst($obj->name);
    #--- $ref values must be RFC3986 compliant URIs ---
    $objname =~ s/::/-/g;
    sprintf '%s-%s', $objname, uc(substr($fingerprint, 0, 10));
}

sub _type_is_enum {
    my $type = shift;

    return 1 if $type->isa('Moose::Meta::TypeConstraint::Enum')
             or $type->isa('Type::Tiny::Enum');

    return 0;
}

1;

__END__

=head1 SYNOPSIS

    plugin 'Swagger';

=head1 DESCRIPTION

Generates an API description of application.

=head1 SPECIFICATION

Compatible with
L<Swagger|http://swagger.io/>/L<OpenAPI|https://www.openapis.org/> Spec 2.0.

=head1 CORS

To enable L<Cross-Origin HTTP Requests|https://developer.mozilla.org/en/docs/Web/HTTP/Access_control_CORS>
you should enable a L<Plack::Middleware::CrossOrigin> middleware with all the
parameters you need (like origins, methods, headers, etc.).

    middleware 'CrossOrigin',
        origins => '*',
        methods => [qw/DELETE GET HEAD OPTIONS PATCH POST PUT/],
        headers => [qw/accept authorization content-type api_key_token/];

Alternatively you can set CORS headers in a L<before|Raisin/HOOKS> hook.

=head1 SECURITY

L<Raisin> has a limited support of OpenAPI security objects. To make it generate
security objects configure it in the way it described below.

Add a B<api_key> security via B<stoken> header.

    swagger_security(name => 'stoken', in => 'header', type => 'api_key');

Add the header name to L<Raisin::Plugin::Swagger/CORS> headers if you use B<api_key>.

    middleware 'CrossOrigin',
        origins => '*',
        methods => [qw/DELETE GET HEAD OPTIONS PATCH POST PUT/],
        headers => [qw/stoken accept authorization content-type/];

=head3 Limitations

=over

=item * L<Raisin> doesn't support per operation security.

=item * L<Raisin> doesn't support B<oauth2>, only B<basic> and B<api_key> are supported.

=back

=head3 Example Application

Example of a secured application.

    use strict;
    use warnings;

    middleware '+MyAuthMiddleware';

    middleware 'CrossOrigin',
        origins => '*',
        methods => [qw/DELETE GET HEAD OPTIONS PATCH POST PUT/],
        headers => [qw/stoken accept authorization content-type/];

    plugin 'Swagger';
    swagger_security(name => 'stoken', in => 'header', type => 'api_key');

    get sub { { data => 'ok' } };

    run;

Example of a middleware used in the application.

    package Auth;

    use strict;
    use warnings;

    use parent 'Plack::Middleware';
    use Plack::Request;

    sub call {
        my ($self, $env) = @_;

        my $req = Plack::Request->new($env);

        if (($req->header('stoken') // '') eq 'secret' || $req->path eq '/swagger.json') {
            $self->app->($env);
        }
        else {
            [403, [], ['forbidden']];
        }
    }

    1;

=head1 FUNCTIONS

=head3 swagger_setup

Configures base OpenAPI parameters, be aware they aren't validating
and passing to the specification as is.

Properly configured section has following attributes:
B<title>, B<description>, B<terms_service>, B<contact> and B<license>.

B<Contact> has B<name>, B<url>, B<email>.

B<License> has B<name> and B<url>.

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

=head3 swagger_security

Configures OpenAPI security options.

Allowed types are B<basic>, B<api_key> and B<oauth2>.

For more information please check OpenAPI specification and L<Raisin::Plugin::Swagger/SECURITY>.

=cut
