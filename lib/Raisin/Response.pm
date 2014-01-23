package Raisin::Response;

use strict;
use warnings;

use Carp;
use Encode;
use base 'Plack::Response';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self;
}

sub json { shift->content_type('application/json') }
sub text { shift->content_type('text/plain') }
sub xml  { shift->content_type('application/xml') }
sub yaml { shift->content_type('application/yaml') }

sub _encode_body {
    my ($self, $body) = @_;

    if ($self->content_type eq 'application/yaml') {
        require YAML;
        YAML::Dump($body);
    }
    else {
        require JSON;
        JSON::encode_json($body);
    }
}

sub rendered {
    my ($self, $rendered) = @_;
    $self->{rendered} = $rendered if $rendered;
    $self->{rendered};
}

sub render {
    my ($self, $body) = @_;
    $body ||= '';

    $self->status(200) if not $self->status;
    $self->text if not $self->content_type;

    if (ref $body) {
        $body = $self->_encode_body($body);
    }

    $self->body(encode 'UTF-8', $body); # XXX Encode?
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
    $self->render("$code - $message");
}

1;
