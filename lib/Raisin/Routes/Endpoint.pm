package Raisin::Routes::Endpoint;

use strict;
use warnings;

use Raisin::Attributes;

has 'check' => {};
has 'code';
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
    for (@{ $self->params }) {
        if ($_->named && (my $re = $_->regex)) {
            if (my $re = $_->regex) {
                $re =~ s/[\$^]//g;
                $self->{check}{ $_->name } = $re;
            }
        }
    }

    $self->regex($self->_build_regex);
    $self;
}

sub _build_regex {
    my $self = shift;
    return $self->path if ref($self->path) eq 'Regexp';

    my $PAT = '(.?)([:*?])(\w+)';
    my $regex =  $self->path;
    $regex =~ s#$PAT#$self->_rep_regex($1, $2, $3)#eg;
    $regex =~ s/[{}]//g;
    #NOTE: temporarly disabled: $regex .= '/?' if $regex !~ m#/$#;
    $regex .= '(?<format>\.\w+)?';
    $regex .= '$';

    qr/^$regex/;
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

    return if !$method || $method ne $self->method;
    return if not (my @matched = $path =~ $self->regex);

    my %captured = %+;
    my %named = map { $_ => $+{$_} } keys %captured;

    if ($named{format}) {
        my $format = delete $named{format};
        $self->format(substr($format, 1));
    }

    foreach my $p (@{ $self->params }) {
        next unless $p->named;
        my $copy = $named{$p->name};
        return unless $p->validate(\$copy, 'shh!');
    }

    $self->named(\%named);

    1;
}

1;

__END__

=head1 NAME

Raisin::Routes::Endpoint - Endpoint class for Raisin::Routes.

=head1 ACKNOWLEDGEMENTS

This module borrowed from L<Kelp::Routes::Pattern>.

=cut
