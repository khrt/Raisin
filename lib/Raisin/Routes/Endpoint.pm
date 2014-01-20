package Raisin::Routes::Endpoint;

use strict;
use warnings;

use feature ':5.12';

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

use Data::Dumper;
    @$self{keys %args} = values %args;

#say $self->path;
    # Check index
    $self->{check} = {};
    for (@{ $self->params }) {
        if ($_->named && (my $re = $_->regex)) {
            $re =~ s/[\$^]//g;
            $self->{check}{ $_->name } = $re;
        }
#        $self->{defaults}{ $_->name } = $_->value;
    }
#warn Dumper $self;

    $self->{regex} = $self->_build_regex;
    $self;
}

sub check { shift->{check} }
sub code { shift->{code} }
#sub defaults { shift->{defaults} }
sub method { shift->{method} }
sub params { shift->{params} }
sub path { shift->{path} }
sub regex { shift->{regex} }
sub tokens_re { shift->{tokens_re} }

sub _build_regex {
    my ($self, %args) = @_;
    return $self->path if ref($self->path) eq 'Regexp';

    my $PAT = '(.?)([:*?])(\w+)';
    my $regex =  $self->path;
    $regex =~ s#$PAT#$self->_rep_regex($1, $2, $3)#eg;
    $regex =~ s/[{}]//g;
    $regex .= '/?' if $regex !~ m#/$#;
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

    my %named = map { $_ => $+{$_} } keys %+;
#    for (keys %named) {
#        if (my $value = $self->defaults->{$_}) {
#            $named{$_} = $value if not exists $named{$_};
#        }
#    }
    $self->named(\%named);

#    # Initialize the param array, containing the values of the
#    # named placeholders in the order they appear in the regex.
#    if ( my @tokens = @{ $self->{_tokens} } ) {
#        $self->param( [ map { $named{$_} } @tokens ] );
#    }
#    else {
#        $self->param( \@matched );
#    }

    1;
}

sub named {
    my ($self, $named) = @_;
    $self->{named} = $named if $named;
    $self->{named};
}

1;

__END__

=pod

=head1 NAME

Raisin::Routes::Endpoint

=head1 ACKNOWLEDGEMENTS

This module heavily borrowed from L<Kelp::Routes::Pattern>.

=cut
