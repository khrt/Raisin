package Raisin::Plugin::Format::YAML;

use strict;
use warnings;

use base 'Raisin::Plugin';

use YAML qw(Dump Load);

sub build {
    my ($self, %args) = @_;

    $self->app->{default_content_type} = $args{content_type} || 'application/yaml';
    $self->register(
        'deserialize' => sub { deserialize($_[1]) },
        'serialize'   => sub { serialize($_[1]) },
    );
}

sub deserialize { Load shift }
sub serialize { Dump shift }

1;

__END__

=head1 NAME

Raisin::Plugin::Format::YAML - YAML serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<deserialize> and C<serialize> methods for Raisin.

=cut
