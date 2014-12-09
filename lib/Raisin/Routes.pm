package Raisin::Routes;

use strict;
use warnings;

use Carp;
use List::Util 'pairs';

use Raisin::Attributes;
use Raisin::Param;
use Raisin::Routes::Endpoint;

has 'cache';
has 'list';
has 'routes';

sub new {
    my $class = shift;
    my $self = bless { id => rand() }, $class;

    $self->cache({});
    $self->list({});
    $self->routes([]);

    $self;
}

# *method => ''
# *path => ''
# *code => sub {}
#
# api_format => ''
# desc => ''
# named => []
# params => []
sub add {
    my ($self, %params) = @_;

    my $method = uc $params{method};
    my $path = $params{path};

    if (!$method || !$path) {
        carp "Method and path are required";
        return;
    }

    my $code = $params{code};
    # Support only code as route destination
    if (!$code || !(ref($code) eq 'CODE')) {
        carp "Invalid route params for $method $path";
        return;
    }

    my $desc = $params{desc};

    my @pp;
    for my $key (qw(params named)) {
        for my $p (pairs @{ $params{$key} }) {
            push @pp, Raisin::Param->new(
                named => $key eq 'named',
                type => $p->[0], # -> requires/optional
                spec => $p->[1], # -> { name => ..., type => ... }
            );
        }
    }

    if (ref($path) && ref($path) ne 'Regexp') {
        carp "Route `$path` should be SCALAR or Regexp";
        return;
    }

    if (!ref($path)) {
        $path =~ s{(.+)/$}{$1};
    }

    my $ep
        = Raisin::Routes::Endpoint->new(
            api_format => $params{api_format},
            code => $code,
            desc => $desc,
            method => $method,
            params => \@pp,
            path => $path,
        );
    push @{ $self->{routes} }, $ep;

    if ($self->list->{$method}{$path}) {
        carp "Route `$path` via `$method` is redefined";
    }
    $self->list->{$method}{$path} = scalar @{ $self->{routes} };
}

sub find {
    my ($self, $method, $path) = @_;

    my $cache_key = lc "$method:$path";
    my $routes
        = exists $self->cache->{$cache_key}
        ? $self->cache->{$cache_key}
        : $self->routes;

    my @found = grep { $_->match($method, $path) } @$routes;

    $self->cache->{$cache_key} = \@found;
    $found[0];
}

1;

__END__

=head1 NAME

Raisin::Routes - Routing class for Raisin.

=head1 SYNOPSIS

    use Raisin::Routes;
    my $r = Raisin::Routes->new;

    my $params = { require => ['name', ], };
    my $code = sub { { name => $params{name} } }

    $r->add('GET', '/user', params => $params, $code);
    my $route = $r->find('GET', '/user');

=head1 DESCRIPTION

The router provides the connection between the HTTP requests and the web
application code.

=over

=item B<Adding routes>

    $r->add('GET', '/user', params => $params, $code);

=cut

=item B<Looking for a route>

    $r->find($method, $path);

=cut

=back

=head1 PLACEHOLDERS

Regexp

    qr#/user/(\d+)#

Required

    /user/:id

Optional

    /user/?id

=head1 METHODS

=head2 add

Adds a new route

=head2 find

Looking for a route

=head1 ACKNOWLEDGEMENTS

This module was inspired by L<Kelp::Routes>.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
