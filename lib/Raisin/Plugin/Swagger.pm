package Raisin::Plugin::Swagger;

use strict;
use warnings;

use parent 'Raisin::Plugin';

use JSON 'encode_json';

use constant SWAGGER_VERSION => '1.2';

sub build {
    my ($self, %args) = @_;

    # Enable CORS
    if ($args{enable} && lc($args{enable}) eq 'cors') {
        $self->app->add_middleware(
            'CrossOrigin',
            origins => '*',
            methods => [qw(GET POST DELETE PUT PATCH OPTIONS)],
            headers => [qw(api_key Authorization Content-Type)]
        );
    }

    $self->register(build_api_spec => sub { $self->build_api_spec });
}

sub build_api_spec {
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
        swaggerVersion => SWAGGER_VERSION,
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
        code => sub { encode_json \%index }
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
            code => sub { encode_json \%description }
        );
    }

    $self->{done} = 1;
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

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
