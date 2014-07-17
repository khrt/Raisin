package Raisin::Routes::Endpoint;

use strict;
use warnings;

use Raisin::Attributes;

has 'api_format';
has 'check' => {};
has 'code';
has 'desc';
has 'format';
has 'method';
has 'named';
has 'params';
has 'path';
has 'regex';
has 'tokens_re';

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    @$self{keys %args} = values %args;

    # Populate params index
    for my $p (@{ $self->params }) {
        if ($p->named && (my $re = $p->regex)) {
            if (my $re = $p->regex) {
                $re =~ s/[\$^]//g;
                $self->{check}{ $p->name } = $re;
            }
        }
    }

    $self->regex($self->_build_regex);
    $self;
}

sub _build_regex {
    my $self = shift;
    return $self->path if ref($self->path) eq 'Regexp';

    my $regex = $self->path;

    $regex =~ s/(.?)([:*?])(\w+)/$self->_rep_regex($1, $2, $3)/eg;
    $regex =~ s/[{}]//g;

    $regex .= do {
        if ($self->api_format) {
            "(?<format>\.${ \$self->api_format })?";
        }
        else {
            '(?<format>\.\w+)?';
        }
    };

    qr/^$regex$/;
}

sub _rep_regex {
    my ($self, $char, $switch, $token) = @_;

    my ($a, $b, $r) = ("(?<$token>", ')', undef);

    for ($switch) {
        if ($_ eq ':' || $_ eq '?') {
            $r = $a . ($self->check->{$token} // '[^\/.]+') . $b;
        }
        if ($_ eq '*') {
            $r = $a . '.+' . $b;
        }
    }

    $char = $char . '?' if $char eq '/' && $switch eq '?';
    $r .= '?' if $switch eq '?';

    return $char . $r;
}

sub match {
    my ($self, $method, $path) = @_;

    $self->{format} = undef;
    $self->{named} = undef;

    return if !$method || lc($method) ne lc($self->method);
    return if $path !~ $self->regex;

    my %captured = %+;

    if ($captured{format}) {
        my $format = delete $captured{format};
        # delete prepending full stop
        $self->format(substr($format, 1));
    }

    foreach my $p (@{ $self->params }) {
        next unless $p->named;
        my $copy = $captured{ $p->name };
        return unless $p->validate(\$copy, 'quite');
    }

    $self->named(\%captured);

    1;
}

1;

__END__

=head1 NAME

Raisin::Routes::Endpoint - Endpoint class for Raisin::Routes.

=head1 ACKNOWLEDGEMENTS

This module borrowed from L<Kelp::Routes::Pattern>.

=cut
