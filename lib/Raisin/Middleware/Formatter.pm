package Raisin::Middleware::Formatter;

use strict;
use warnings;

use parent 'Plack::Middleware';

use HTTP::Status qw(:constants);
use Plack::Request;
use Plack::Response;
use Plack::Util;
use Plack::Util::Accessor qw(
    default_format
    format
    encoder
    decoder
);

sub call {
    my ($self, $env) = @_;

    # Pre-process
    my $req = Plack::Request->new($env);

    if ($req->content) {
        my %media_types_map_flat_hash = $self->decoder->media_types_map_flat_hash;

        my $format = $media_types_map_flat_hash{ $req->content_type };
        unless ($format) {
            Raisin::log(info => "unsupported media type: ${ \$req->content_type }");
            return Plack::Response->new(HTTP_UNSUPPORTED_MEDIA_TYPE)->finalize;
        }
        $env->{'raisinx.decoder'} = $format;

        my $d = Plack::Util::load_class($self->decoder->for($format));
        $env->{'raisinx.body_params'} = $d->deserialize($req->content);
    }

    my $res = $self->app->($env);
    my $content_format  = Plack::Util::header_get($res->[1], 'Content-type');
    my $format = $content_format || $self->negotiate_format($req);

    unless ($format) {
        return Plack::Response->new(HTTP_NOT_ACCEPTABLE)->finalize;
    }
    $env->{'raisinx.encoder'} = $format;

    $res = $self->app->($env);
    # Post-process
    Plack::Util::response_cb($res, sub {
        # TODO: delayed responses

        my $res = shift;
        my $r = Plack::Response->new(@$res);

        if (ref $r->body) {
            my $s = Plack::Util::load_class($self->encoder->for($format));

            $r->content_type($s->content_type) unless $r->content_type;
            $r->body($s->serialize($r->body));
        }

        @$res = @{ $r->finalize };
        return;
    });
}

sub _accept_header_set { length(shift || '') }
sub _path_has_extension {
    my $path = shift;
    my @chunks = split /\./, $path;
    scalar(@chunks) > 1;
}

sub negotiate_format {
    my ($self, $req) = @_;

    # PRECEDENCE:
    #   - extension
    #   - headers
    #   - default

    my @formats = do {
        if (_path_has_extension($req->path)) {
            $self->format_from_extension($req->path);
        }
        elsif (_accept_header_set($req->header('Accept'))) {
            $self->format_from_header($req->header('Accept'));
        }
        else {
            $self->default_format;
        }
    };

    if ($self->format && !scalar grep { $self->format eq $_ } @formats) {
        return;
    }

    shift @formats;
}

sub format_from_extension {
    my ($self, $path) = @_;

    my @p = split /\./, $path;
    return if scalar @p <= 1;

    my %media_types_map_flat_hash = $self->encoder->media_types_map_flat_hash;
    my $format = $media_types_map_flat_hash{ $p[-1] };
    return unless $format;

    $format;
}

sub format_from_header {
    my ($self, $accept) = @_;
    return unless $accept;

    my %media_types_map_flat_hash = $self->encoder->media_types_map_flat_hash;
    # Add a default format as a `*/*`
    $media_types_map_flat_hash{'*/*'} = $self->default_format;

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

1;
__END__

=head1 NAME

Raisin::Middleware::Formatter - A parser/formatter middleware for L<Raisin>.

=head1 DESCRIPTION

Parses and formats the data it gets from requests and responses if it's needed.

=head1 METHODS

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
are not specified it fallback to default format.

=head2 format_from_extension

Extracts an extension from a path, and if exists looks for a formatter.

=head2 format_from_header

Parses C<Accept> header for known formatters.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
