package Raisin::Routes;

use strict;
use warnings;

use Carp;
use Raisin::Param;
use Raisin::Routes::Endpoint;
use Raisin::Attributes;

has 'cache' => {};
has 'list' => {};
has 'routes' => [];

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self;
}

sub add {
    my ($self, $method, $path, @args) = @_;

    if (!$method || !$path) {
        carp "Method and path are required";
        return;
    }

    # @args:
    #   * [optional] named => []
    #   * [optional] params => []
    #   * [optional] path
    #   * [required] code ref

    my $code = pop @args;
    # Support only code as route destination
    if (!$code || !(ref($code) eq 'CODE')) {
        carp "Invalid route params for ${ uc $method } $path";
        return;
    }

    # Named route params
    if (scalar @args == 1 || scalar @args == 3) {
        $path = $path . '/' . pop @args;
    }

    my @params;
    if (@args && (my %args = @args)) {
        foreach my $key (qw(params named)) {
            for (my $i = 0; $i < scalar @{ $args{$key} || [] }; $i += 2) {
                push @params, Raisin::Param->new(
                    named => $key eq 'named' ? 1 : 0,
                    param => [$args{$key}[$i], $args{$key}[$i + 1]]
                );
            }
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
            code => $code,
            params => \@params,
            method => $method,
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

    my @found
    #   = sort { $b->bridge <=> $a->bridge || $a->pattern cmp $b->pattern }
        = grep { $_->match($method, $path) } @$routes;

    $self->cache->{$cache_key} = \@found;
    \@found;
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

=cut
