package Raisin::Plugin::APIDocs;

use strict;
use warnings;

use base 'Raisin::Plugin';

use JSON 'encode_json';

use constant SWAGGER_VERSION => '1.2';

sub build {
    my $self = shift;

    # Enable CORS
    $self->app->add_middleware(
        'CrossOrigin',
        origins => '*',
        methods => [qw(GET POST DELETE PUT PATCH OPTIONS)],
        headers => [qw(api_key Authorization Content-Type)]
    );

    $self->register(build_api_docs => sub { $self->build_api_docs });
}

# TODO
sub build_api_docs {
    my $self = shift;
    return 1 if $self->{done};

    my $app = $self->app;

    my %apis;

    # Prepare API data
    for my $r (@{ $app->routes->routes }) {
        my $path = $r->path;
        $path =~ s#:([^/]+)#{$1}#g;

        my ($ns) = $path =~ m#^(/[^/]+)#;

        my @parameters;
        for my $p (@{ $r->params }) {

            # Types
            #  - boolean
            #  - integer, int32
            #  - integer, int64
            #  - number, double
            #  - number, float
            #  - string
            #  - string, byte
            #  - string, date
            #  - string, date-time

            my $param_type
                = $p->named
                ? 'path'
                : $r->method =~ /POST|PUT/
                    ? 'form'
                    : 'query';

            my %p = (
                allowMultiple => JSON::true,
                defaultValue => $p->default || JSON::false,
                description => uc($p->name) . ' DESCRIPTION',
                format => ref $p->type,
                name => $p->name,
                paramType => $param_type,
                required => $p->required ? JSON::true : JSON::false,
                type => $p->type->name,
            );
            push @parameters, \%p;
        }

        my %api = (
            path => $path,
            operations => [{
                method => $r->method,
                nickname => $r->method . '_' . $path,
                notes => '',
                parameters => \@parameters,
                summary => '',
                type => '',
            }],
        );

        push @{ $apis{$ns} }, \%api;
    }

    my %template = (
        swaggerVersion => SWAGGER_VERSION,
    );
    $template{apiVersion} = $self->app->api_version if $self->app->api_version;

    # Prepare index
    my %index = (%template);
    for my $ns (keys %apis) {
        my $api = {
            path => $ns,
            description => "Operations about ${ \( $ns =~ m#/(.+)# ) }",
        };

        push @{ $index{apis} }, $api;
    }

    # Add routes
    $app->add_route(
        GET => '/api-docs',
        sub { encode_json \%index }
    );

    for my $ns (keys %apis) {
        my $base_path = $app->req ? $app->req->base->as_string : '';
        $base_path =~ s#/$##;

        my %description = (
            %template,
            apis => $apis{$ns},
            basePath => $base_path,
            produces => [$app->default_content_type],
            resourcePath => $ns,
        );

        $app->add_route(
            GET => "/api-docs${ns}",
            sub { encode_json \%description }
        );
    }

    $self->{done} = 1;
}

1;

__END__

=head1 NAME

Raisin::Plugin::APIDocs - Generate API documentation.

=head1 SYNOPSIS

    plugin 'APIDocs';

=head1 DESCRIPTION

Generate L<Swagger|https://github.com/wordnik/swagger-core>
compatible API documentaions.

Provides documentation in Swagger compatible format by C</api-docs> URL.
You can use this url in L<Swagger UI|http://swagger.wordnik.com/>.

=cut
