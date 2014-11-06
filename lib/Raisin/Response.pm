package Raisin::Response;

use strict;
use warnings;

use parent 'Plack::Response';

use Carp;
use Encode 'encode';

use Raisin::Util;

sub new {
    my ($class, $app) = @_;
    my $self = $class->SUPER::new();
    $self->{app} = $app;
    $self;
}

sub app { shift->{app} }

sub serialize {
    my ($self, $format, $data) = @_;

    my $serializer = do {
        if (my $f = Raisin::Util::detect_serializer($format)) {
            Plack::Util::load_class(Raisin::Util::make_serializer_class($f));
        }
        elsif ($self->app->can('serializer')) {
            $self->app->serializer;
        }
        elsif (ref $data) {
            Plack::Util::load_class($self->app->api_default_format);
        }
    };

    if ($serializer) {
        $data = $serializer->serialize($data);
        $self->content_type($serializer->content_type) if not $self->content_type;
    }

    $data;
}

sub rendered {
    my ($self, $rendered) = @_;
    $self->{rendered} = $rendered if defined $rendered;
    $self->{rendered};
}

sub render {
    my ($self, $format, $body) = @_;
    $body ||= $self->body;
    $self->status(200) if not $self->status;

    if (ref $body) {
        $body = $self->serialize($format, $body);
    }

    $self->content_type('text/plain') if not $self->content_type;
    $self->body(encode 'UTF-8', $body);
    $self->rendered(1);

    $self;
}

sub render_401 { shift->render_error(401, shift || 'Unauthorized') }
sub render_404 { shift->render_error(404, shift || 'Nothing found') }
sub render_500 { shift->render_error(500, shift || 'Internal error') }

sub render_error {
    my ($self, $code, $message) = @_;

    $self->status($code);
    # TODO __DATA__ templates
    $self->render(undef, $message);
}

1;

__END__

=head1 NAME

Raisin::Response - Response class for Raisin.

=head1 SYNOPSIS

    Raisin::Response->new;

=head1 DESCRIPTION

Extends L<Plack::Response>.

=head1 METHODS

=head3 serialize

=head3 rendered

=head3 render

=head3 render_401

=head3 render_404

=head3 render_500

=head3 render_error

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
