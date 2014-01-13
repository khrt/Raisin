package Raisin::Response;

use strict;
use warnings;

use Carp;
use base 'Plack::Response';

sub new {
    my ($class, $app) = @_;
    my $self = $class->SUPER::new();
    $self->{app} = $app;
    $self;
}

sub json { shift->content_type('application/json') }
sub plain { shift->content_type('text/plain') }

sub rendered {
    my ($self, $rendered) = @_;
    $self->{rendered} = $rendered if $rendered;
    $self->{rendered};
}

sub render {
    my ($self, $body) = @_;
    $body ||= '';

    $self->status(200) if not $self->status;
    $self->content_type('text/plain') if not $self->content_type;

    # TODO
    if ($self->content_type eq 'application/json') {
        use JSON::XS 'encode_json';
        $body = encode_json $body;
    }

    $self->body($body); # XXX Encode?
    $self->rendered(1);
    $self;
}

sub render_401 { shift->render_error(401, shift || 'Unauthorized') }
sub render_404 { shift->render_error(404, shift || 'Nothing found') }
sub render_500 { shift->render_error(500, shift || 'Internal error' ) }

sub render_error {
    my ($self, $code, $message) = @_;

    $self->status($code);
    # TODO __DATA__ templates
    $self->render("$code - $message");
}

1;
