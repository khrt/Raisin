package Raisin::Response;

use strict;
use warnings;

use base 'Plack::Response';

use Carp;
use Encode 'encode';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self;
}

sub rendered {
    my ($self, $rendered) = @_;
    $self->{rendered} = $rendered if defined $rendered;
    $self->{rendered};
}

sub render {
    my ($self, $body) = @_;
    $body ||= '';
    $self->status(200) if not $self->status;
    $self->content_type('text/plain') if not $self->content_type;

    if (ref $body) {
        require Data::Dumper;
        $body = Data::Dumper->new([$body], ['body'])
            ->Purity(1)->Terse(1)->Deepcopy(1)->Dump;
    }

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
    $self->render("$code - $message");
}

1;
