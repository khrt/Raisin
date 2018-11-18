package Raisin::Param;

use strict;
use warnings;

use Carp;
use Plack::Util::Accessor qw(
    named
    required

    default
    desc
    enclosed
    name
    regex
    type
    coerce
);

use Raisin::Util;

my @ATTRIBUTES = qw(name type default regex desc coerce);
my @LOCATIONS = qw(path formData body header query);

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $self->{named} = $args{named} || 0;
    $self->{required} = $args{type} =~ /^require(s|d)$/ ? 1 : 0;

    return unless $self->_parse($args{spec});

    $self;
}

sub _parse {
    my ($self, $spec) = @_;

    $self->{$_} = $spec->{$_} for @ATTRIBUTES;

    if ($spec->{in}) {
        return unless $self->in($spec->{in});
    }

    if ($spec->{encloses}) {
        if ($self->type->name eq 'HashRef') {
            $self->{enclosed} = _compile_enclosed($spec->{encloses});
        }
        else {
            Raisin::log(
                warn => 'Ignoring enclosed parameters for `%s`, type should be `HashRef` not `%s`',
                $self->name, $self->type->name
            );
        }
    }

    $self->{coerce} = defined($spec->{coerce}) ? $spec->{coerce} : 1;

    return 1;
}

sub _compile_enclosed {
    my $params = shift;

    my @enclosed;
    my $next_param = Raisin::Util::iterate_params($params);
    while (my ($type, $spec) = $next_param->()) {
        last unless $type;

        push @enclosed, Raisin::Param->new(
            named => 0,
            type => $type, # -> requires/optional
            spec => $spec, # -> { name => ..., type => ... }
        );
    }

    \@enclosed;
}

sub display_name { shift->name }

sub in {
    my ($self, $value) = @_;

    if (defined $value) {
        unless (grep { $value eq $_ } @LOCATIONS) {
            Raisin::log(warn => '`%s` should be one of: %s',
                $self->name, join ', ', @LOCATIONS);
            return;
        }

        $self->{in} = $value;
    }

    $self->{in};
}

sub validate {
    my ($self, $ref_value, $quiet) = @_;

    # Required and empty
    # Only optional parameters can have default value
    if ($self->required && !defined($$ref_value)) {
        Raisin::log(warn => '`%s` is required', $self->name) unless $quiet;
        return;
    }

    # Optional and empty
    if (!$self->required && !defined($$ref_value)) {
        Raisin::log(info => '`%s` optional and empty', $self->name);
        return 1;
    }

    # Type check
    eval {
        if ($self->type->has_coercion && $self->coerce) {
            $$ref_value = $self->type->coerce($$ref_value);
        }

        if ($self->type->isa('Moose::Meta::TypeConstraint')) {
            $self->type->assert_valid($$ref_value);
        }
        else {
            $$ref_value = $self->type->($$ref_value);
        }
    };
    if (my $e = $@) {
        unless ($quiet) {
            Raisin::log(warn => 'Param `%s` didn\'t pass constraint `%s` with value "%s"',
                $self->name, $self->type->name, $$ref_value);
        }
        return;
    }

    # Nested
    if ($self->type->name eq 'HashRef' && $self->enclosed) {
        for my $p (@{ $self->enclosed }) {
            my $v = $$ref_value;

            if ($self->type->name eq 'HashRef') {
                $v = $v->{ $p->name };
            }

            return unless $p->validate(\$v, $quiet);
        }
    }
    # Regex
    elsif ($self->regex && $$ref_value !~ $self->regex) {
        unless ($quiet) {
            Raisin::log(warn => 'Param `%s` didn\'t match regex `%s` with value "%s"',
                $self->name, $self->regex, $$ref_value);
        }
        return;
    }

    1;
}

1;

__END__

=head1 NAME

Raisin::Param - Parameter class for Raisin.

=head1 DESCRIPTION

Parameter class for L<Raisin>. Validates request paramters.

=head3 coerce

Returns coerce flag. If C<true> attempt to coerce a value will be made at validate stage.

By default set to C<true>.

=head3 default

Returns default value if exists or C<undef>.

=head3 desc

Returns parameter description.

=head3 name

Returns parameter name.

=head3 display_name

An alias to L<Raisin::Param/name>.

=head3 named

Returns C<true> if it's path parameter.

=head3 regex

Return paramter regex if exists or C<undef>.

=head3 required { shift->{required} }

Returns C<true> if it's required parameter.

=head3 type

Returns parameter type object.

=head3 in

Returns the location of the parameter: B<query, header, path, formData, body>.

=head3 validate

Process and validate parameter. Takes B<reference> as the input paramter.

    $p->validate(\$value);

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
