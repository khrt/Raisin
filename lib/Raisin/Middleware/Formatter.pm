#!perl
#PODNAME: Raisin::Middleware::Formatter
#ABSTRACT: A parser/formatter middleware for L<Raisin>.

use strict;
use warnings;

package Raisin::Middleware::Formatter;

use parent 'Plack::Middleware';

use File::Basename qw(fileparse);
use HTTP::Status qw(:constants);
use Scalar::Util qw{ blessed reftype openhandle };
use Plack::Request;
use Plack::Response;
use Plack::Util;
use Plack::Util::Accessor qw(
    default_format
    format
    encoder
    decoder
    raisin
);

sub call {
    my ($self, $env) = @_;

    # Pre-process
    my $req = Plack::Request->new($env);

    if ($req->content) {
        my %media_types_map_flat_hash = $self->decoder->media_types_map_flat_hash;

        my ($ctype) = split /;/, $req->content_type, 2;
        my $format = $media_types_map_flat_hash{$ctype};
        unless ($format) {
            Raisin::log(info => "unsupported media type: ${ \$req->content_type }");
            return Plack::Response->new(HTTP_UNSUPPORTED_MEDIA_TYPE)->finalize;
        }
        $env->{'raisinx.decoder'} = $format;

        my $d = Plack::Util::load_class($self->decoder->for($format));
        $env->{'raisinx.body_params'} = $d->deserialize($req);
    }

    my $format = $self->negotiate_format($req);
    unless ($format) {
        return Plack::Response->new(HTTP_NOT_ACCEPTABLE)->finalize;
    }
    $env->{'raisinx.encoder'} = $format;

    my $res = $self->app->($env);
    # Post-process
    Plack::Util::response_cb($res, sub {

        my $res = shift;
        my $r = Plack::Response->new(@$res);

        # The application may decide on the fly to return a different
        # content type than we negotiated above. In that case it becomes
        # responsible for updating $env appropriately, and also
        # specifying the encoder to use.
        my $format = $env->{'raisinx.encoder'};

        # If the body is a data structure of some sort, finalize it now,
        # BUT NOT if it's a file handle (broadly construed). In that case
        # treat it as a deferred response.
        if (ref $r->body && !_is_a_handle($r->body)) {
            my $s = Plack::Util::load_class($self->encoder->for($format));

            $r->content_type($s->content_type) unless $r->content_type;
            $r->body($s->serialize($r->body));
        }

        @$res = @{ $r->finalize };
        return;
    });
}

# Test whether the argument is a "handle," meaning that it's either
# a built-in handle or an IO::Handle-like object.  It's a file handle
# if fileno or Scalar::Util::openhandle think it is, or if it supports
# a "getline" and a "close" method.
sub _is_a_handle {
    my ($var) = @_;

    return
        ( ( reftype $var // '' ) eq 'GLOB' && ( defined fileno($var) || defined openhandle($var) ) )
        ||
        ( blessed $var && $var->can('getline') && $var->can('close') )
        ;
}

sub _accept_header_set { length(shift || '') }
sub _path_has_extension {
    my $path = shift;
    my (undef, undef, $suffix) = fileparse($path, qr/\..[^.]*$/);
    $suffix;
}

sub negotiate_format {
    my ($self, $req) = @_;

    my @allowed_formats = $self->allowed_formats_for_requested_route($req);

    # PRECEDENCE:
    #   - known extension
    #   - headers
    #   - default
    my @wanted_formats = do {
        my $ext_format = $self->format_from_extension($req->path);
        if ($ext_format) {
            $ext_format;
        }
        elsif (_accept_header_set($req->header('Accept'))) {
            # In case of wildcard matches, we default to first allowed format
            $self->format_from_header($req->header('Accept'), $allowed_formats[0]);
        }
        else {
            $self->default_format;
        }
    };

    my @matching_formats = grep {
        my $format = $_;
        grep { $format && $format eq $_ } @allowed_formats
    } @wanted_formats;

    shift @matching_formats;
}

sub format_from_extension {
    my ($self, $path) = @_;
    return unless $path;

    my $ext = _path_has_extension($path);
    return unless $ext;

    # Trim leading dot in the extension.
    $ext = substr($ext, 1);

    my %media_types_map_flat_hash = $self->encoder->media_types_map_flat_hash;
    my $format = $media_types_map_flat_hash{$ext};
    return unless $format;

    $format;
}

sub format_from_header {
    my ($self, $accept, $assumed_wildcard_format) = @_;
    return unless $accept;

    my %media_types_map_flat_hash = $self->encoder->media_types_map_flat_hash;
    # Add a default format as a `*/*`
    $media_types_map_flat_hash{'*/*'} = $assumed_wildcard_format;

    my @media_types;
    for my $type (split /\s*,\s*/, $accept) {
        my ($media, $params) = split /;/, $type, 2;
        # Cleaning up media type by deleting a Vendor tree
        $media =~ s/vnd\.[^+]+\+//g;

        next unless my $format = $media_types_map_flat_hash{$media};

        my $q = ($params // '') =~ /q=([\d\.]+)/ ? $1 : 1;

        push @media_types, { format => $format, q => $q };
    }

    map { $_->{format} } sort { $b->{q} <=> $a->{q} } @media_types;
}

sub allowed_formats_for_requested_route {
    my ($self, $req) = @_;
    # Global format has been forced upon entire app
    return $self->format if $self->format;

    # Route specific `produces` restrictions
    if ( $self->raisin ) {
        my $route = $self->raisin->routes->find($req->method, $req->path);
        return @{$route->{produces}} if $route->{produces};
    }

    # Prefer Default, allow all others
    my @allowed = keys %{ $self->encoder->all };
    unshift @allowed, $self->default_format if $self->default_format;
    return @allowed;
}

1;
__END__

=head1 DESCRIPTION

Parses and formats the data it gets from requests and responses if it's needed.

=head1 METHODS

=head2 call

Invokes an application route. Before doing so, it decodes the request content,
if any, and negotiates an output format based on the C<Accept> header of the
request and the C<produces> list for the target route. It post-processes
the response from the endpoint using the appropriate C<Decoder>, ensuring
that it will be a valid PSGI response.

C<call> supports deferred responses by passing the body through unmodified if
it's a file handle -- i.e., the result of calling C<open()>, an C<IO::Handle>
object, or any blessed reference that supports both C<getline()> and
C<close()> methods.

=head2 negotiate_format

Negotiates a format from path extension, C<Accept> header or using default format.

A precedence is following:

=over

=item * extension;
=item * C<Accept> header;
=item * default;

=back

In other words if an extension exists the framework doesn't look for C<Accept>
header. If the extension is not supported the framework throws an error,
the same is for C<Accept> header. Only if both extension and C<Accept> header
are not specified does it fallback to default format.

Having picked a format, the correct encoder is set in
C<< env->{'rasinx.encoder'} >>. Occasionally the application will want to
change the format, for example to return a JSON error response from a
route that normally returns plain text. To do that, change
C<< env->{'rasinx.encoder'} >> to the correct encoder, and make sure that
the response C<Content-Type> header matches it. It's the application's
responsibility in that case to know what it's doing, and not return
content that the client can't accept.

=head2 format_from_extension

Extracts an extension from a path, and if exists looks for a formatter.

=head2 format_from_header

Parses C<Accept> header for known formatters.

=cut
