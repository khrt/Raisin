package Raisin::Param;

use strict;
use warnings;

use Carp;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $self->{named} = $args{named};
    $self->{required} = $args{param}[0] =~ /^require(s|d)$/ ? 1 : 0;

    @$self{qw(name type default regex)} = @{ $args{param}[1] };
    $self;
}

sub required { shift->{required} }
sub named    { shift->{named} }

sub name    { shift->{name} }
sub type    { shift->{type} }
sub default { shift->{default} }
sub regex   { shift->{regex} }

sub validate {
    my ($self, $ref_value) = @_;

    # Required
    # Only optional parameters can has default value
    if ($self->required && !defined($$ref_value)) {
        carp "$self->{name} required but empty!";
        return;
    }

    # Optional and empty
    if (!defined($$ref_value) && !$self->required) {
        #carp STDERR "$self->{name} optional and empty.";
        return 1;
    }

    if ($$ref_value && ref $$ref_value && ref $$ref_value ne 'ARRAY') {
        carp "$self->{name} \$ref_value should be SCALAR or ARRAYREF";
        return;
    }

    my $was_scalar;
    if (ref $$ref_value ne 'ARRAY') {
        $was_scalar = 1;
        $$ref_value = [$$ref_value];
    }

    for my $v (@$$ref_value) {
        if (!$self->type->check($v)) {
            carp "CHECK: `$self->{name}` has invalid value `$v`!";
            return;
        }

        if ($self->regex && $v !~ $self->regex) {
            carp "REGEX: `$self->{name}` has invalid value `$v`!";
            return;
        }

        if (my $in = $self->type->in) {
            $in->(\$v);
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

=head3 required { shift->{required} }

Returns C<true> if it's required parameter.

=head3 named

Returns C<true> if it's path parameter.

=head3 name

Returns parameter name.

=head3 type

Returns paramter type object.

=head3 default

Returns default value if exists or C<undef>.

=head3 regex

Return paramter regex if exists or C<undef>.

=head3 validate

Process and validate parameter. Takes B<reference> as the input paramter.

    $p->validate(\$value);

=cut
