package Raisin::Plugin::Format::JSON;

use strict;
use warnings;

use base 'Raisin::Plugin';

use JSON qw(encode_json decode_json);

sub build {
    my ($self, %args) = @_;

    $self->app->{default_content_type} = $args{content_type} || 'application/json';
    $self->register(
        'deserialize' => sub { decode_json $_[1] },
        'serialize'   => sub { encode_json $_[1] },
    );
}

1;
