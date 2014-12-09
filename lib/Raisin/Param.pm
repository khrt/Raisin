package Raisin::Param;

use strict;
use warnings;

use Carp;
use Raisin::Attributes;

has 'named';
has 'required';

has 'default';
has 'name';
has 'type';
has 'regex';
has 'desc';

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $self->{named} = $args{named};
    $self->{required} = $args{type} =~ /^require(s|d)$/ ? 1 : 0;

    $self->_parse($args{spec});

    $self;
}

sub _parse {
    my ($self, $spec) = @_;
    $self->{$_} = $spec->{$_} for qw(name type default regex desc);
}

sub validate {
    my ($self, $ref_value, $quiet) = @_;

    # Required
    # Only optional parameters can has default value
    if ($self->required && !defined($$ref_value)) {
        #TODO: $self->app->log($e);
        print STDERR "`$self->{name}' is required but empty!\n" unless $quiet;
        return;
    }

    # Optional and empty
    if (!defined($$ref_value) && !$self->required) {
        #carp STDERR "$self->{name} optional and empty.";
        return 1;
    }

    # TODO: validate HASHes
    if ($$ref_value && ref $$ref_value && ref $$ref_value ne 'ARRAY') {
        #TODO: $self->app->log($e);
        print STDERR "`$self->{name}' \$ref_value should be SCALAR or ARRAYREF\n" unless $quiet;
        return 1;
    }

    my $was_scalar;
    if (ref $$ref_value ne 'ARRAY') {
        $was_scalar = 1;
        $$ref_value = [$$ref_value];
    }

    for my $v (@$$ref_value) {
        # Type check
        eval { $v = $self->type->($v) };
        if (my $e = $@) {
            unless ($quiet) {
                #TODO: $self->app->log($e);
                printf STDERR "Param `%s' didn't pass type constraint `%s' with value \"%s\".\n",
                    $self->name, $self->type->name, $v;
            }
            return;
        }

        # Param check
        if ($self->regex && $v !~ $self->regex) {
            unless ($quiet) {
                #TODO: $self->app->log($e);
                printf STDERR "Param `%s' didn't pass regex constraint `%s' with value \"%s\".\n",
                    $self->name, $self->regex, $v;
            }
            return;
        }
    }

    $$ref_value = $$ref_value->[0] if $was_scalar;

    1;
}

1;

__END__

=head1 NAME

Raisin::Param - Parameter class for Raisin.

=head1 DESCRIPTION

Parameter class for L<Raisin>. Validates request paramters.

=head3 default

Returns default value if exists or C<undef>.

=head3 desc

Returns parameter description.

=head3 name

Returns parameter name.

=head3 named

Returns C<true> if it's path parameter.

=head3 regex

Return paramter regex if exists or C<undef>.

=head3 required { shift->{required} }

Returns C<true> if it's required parameter.

=head3 type

Returns parameter type object.

=head3 validate

Process and validate parameter. Takes B<reference> as the input paramter.

    $p->validate(\$value);

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
