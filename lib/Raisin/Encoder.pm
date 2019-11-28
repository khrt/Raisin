#!perl
#PODNAME: Raisin::Encoder
#ABSTRACT: A helper for L<Raisin::Middleware::Formatter> over encoder modules

use strict;
use warnings;

package Raisin::Encoder;

use Plack::Util;
use Plack::Util::Accessor qw(registered);

sub new { bless { registered => {} }, shift }

sub register {
    my ($self, $format, $class) = @_;
    $self->{registered}{$format} = $class;
}

sub builtin {
    {
        json => 'Raisin::Encoder::JSON',
        yaml => 'Raisin::Encoder::YAML',
        text => 'Raisin::Encoder::Text',
    };
}

sub all {
    my $self = shift;
    my %s = (
        %{ $self->builtin },
        %{ $self->registered },
    );
    \%s;
}

sub for {
    my ($self, $format) = @_;
    $self->all->{$format};
}

sub media_types_map_flat_hash {
    my $self = shift;
    my $s = $self->all;

    my %media_types_map = map {
        Plack::Util::load_class($s->{$_});
        $_ => $s->{$_}->detectable_by;
    } keys %$s;

    my %media_types_map_flat_hash = map {
        my $k = $_; map { $_ => $k } @{ $media_types_map{$k} }
    } keys %media_types_map;

    %media_types_map_flat_hash;
}

1;

__END__

=head1 SYNOPSIS

    my $enc = Raisin::Encoder->new;
    $enc->register(xml => 'Some::XML::Formatter');
    $enc->for('json');
    $enc->media_types_map_flat_hash;

=head1 DESCRIPTION

Provides an easy interface to use and register encoders.

=head1 METHODS

=head2 register

Allows user to register their own encoders.

    $enc->register(xml => 'Some::XML::Formatter');

Also it can override L</builtin> types as the user ones have more precedence.

    $enc->register(json => 'My::Own::JSON::Formatter');

=head2 builtin

Returns a list of encoders which are bundled with L<Raisin>.
They are: L<Raisin::Encoder::JSON>, L<Raisin::Encoder::Text>,
L<Raisin::Encoder::YAML>.

=head2 registered

Returns a list of encoders which were registered by user.

=head2 all

Returns a list of both L</builtin> and L</users>.

=head2 for

Returns a class name for specified format.

=head2 media_types_map_flat_hash

Returns a hash of media types and associated formats.

=cut
