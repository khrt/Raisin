package Raisin::Routes::Endpoint;

use strict;
use warnings;

use Plack::Util::Accessor qw(
    check
    code
    desc
    entity
    method
    named
    params
    path
    regex
    summary
    produces
);

use Raisin::Util;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->check({});
    $self->params([]);

    @$self{ keys %args } = values %args;

    # Populate params index
    for my $p (@{ $self->params }) {
        if ($p->named && (my $re = $p->regex)) {
            $re =~ s/[\$^]//g;
            $self->{check}{ $p->name } = $re;
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

    # Allows any extensions
    $regex .= "(?:\\\.[^.]+?)?";

    qr/^$regex$/;
}

sub _rep_regex {
    my ($self, $char, $switch, $token) = @_;

    my ($a, $b, $r) = ("(?<$token>", ')', undef);

    for ($switch) {
        if ($_ eq ':' || $_ eq '?') {
            $r = $a . ($self->check->{$token} // '[^/]+?') . $b;
        }
        if ($_ eq '*') {
            $r = $a . '.+' . $b;
        }
    }

    $char = $char . '?' if $char eq '/' && $switch eq '?';
    $r .= '?' if $switch eq '?';

    return $char . $r;
}

sub tags {
    my $self = shift;

    unless ($self->{tags}) {
        return [Raisin::Util::make_tag_from_path($self->path)];
    }

    $self->{tags};
}

sub match {
    my ($self, $method, $path) = @_;

    $self->{named} = undef;

    return if !$method || lc($method) ne lc($self->method);
    return if $path !~ $self->regex;

    my %captured = %+;

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

This module was inspired by L<Kelp::Routes::Pattern>.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
