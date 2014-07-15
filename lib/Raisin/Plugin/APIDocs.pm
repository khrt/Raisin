package Raisin::Plugin::APIDocs;

use strict;
use warnings;

use base 'Raisin::Plugin';

use JSON 'encode_json';

use constant SWAGGER_VERSION => '1.2';

sub build {
    my $self = shift;

    # TODO: make configurable
    # Enable CORS
    $self->app->add_middleware(
        'CrossOrigin',
        origins => '*',
        methods => [qw(GET POST DELETE PUT PATCH OPTIONS)],
        headers => [qw(api_key Authorization Content-Type)]
    );

    $self->register(build_api_docs => sub { $self->build_api_docs });
}

# TODO: simplify
sub build_api_docs {
    my $self = shift;
    return 1 if $self->{done};

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
                    description   => $p->desc,
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

        # -> { ns => [api, ...] }
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

        my $content_type = 'application/yaml'; # TODO: add more?

        my %description = (
            %template,
            apis => $apis{$ns},
            basePath => $base_path,
            produces => [$content_type],
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
