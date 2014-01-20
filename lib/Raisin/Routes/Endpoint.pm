package Raisin::Routes::Endpoint;

use strict;
use warnings;

use feature ':5.12';

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    for (keys %args) {
        $self->{$_} = $args{$_};
    }

    $self->{check} = {};
    $self->{regex} = $self->_build;
use Data::Dumper;
warn Dumper $self;

    $self;
}

sub check     { shift->{check} }
sub code      { shift->{code} }
sub declared  { shift->{declared} } # Declared params
sub method    { shift->{method} }
sub path      { shift->{path} }
sub regex     { shift->{regex} }
sub tokens_re { shift->{tokens_re} }

sub _build {
    my ($self, %args) = @_;
    return $self->path if ref($self->path) eq 'Regexp';

    my $PAT = '(.?)([:*?])(\w+)';
    my $regex =  $self->path;
    $regex =~ s{$PAT}{$self->_rep_regex($1, $2, $3)}eg;
    $regex =~ s/[{}]//g;
    $regex .= '/?' if $regex !~ m{/$};
    $regex .= '$';# unless $self->bridge; # XXX XXX XXX

    qr/^$regex/;
}

sub _rep_regex {
    my ($self, $char, $switch, $token) = @_;

    my ($a, $b, $r) = ("(?<$token>", ')', undef);
    for ($switch) {
        if ($_ eq ':' || $_ eq '?') {
            $r = $a . ($self->check->{$token} // '[^\/]+') . $b;
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

    return if !$method || $method ne $self->method;
    return if not (my @matched = $path =~ $self->regex);

    my %params = map { $_ => $+{$_} } keys %+;
    $self->params(\%params);

    1;
}

sub params {
    my ($self, $params) = @_;
    $self->{params} = $params if $params;
    $self->{params};
}

1;

__END__

=pod

=head1 NAME

Raisin::Routes::Endpoint

=head1 ACKNOWLEDGEMENTS

This module heavily borrowed from L<Kelp::Routes::Pattern>.

=cut
