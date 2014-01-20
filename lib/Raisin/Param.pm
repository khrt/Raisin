package Raisin::Param;

use strict;
use warnings;

use feature ':5.12';

use Carp;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_build(@_);
    $self;
}

sub _build {
    my ($self, $required, $options) = @_;

    $self->{required} = $required eq 'required' ? 1 : 0;
    @$self{qw(name type default regex)} = @$options;


}

sub default  { shift->{default} }
sub name     { shift->{name} }
sub regex    { shift->{regex} }
sub required { shift->{required} }
sub type     { shift->{type} }

sub value {
    my ($self, $value) = @_;
    $self->{value} = $value if defined $value;
    $self->{value} // $self->default // $self->type->default // '';
}

sub validate {
    my ($self, $value) = @_;

    # TODO Don't working
    if (!$value && $self->value) {
        carp 'use default value';
        return 1;
    }

    if (!$value && !$self->required) {
        carp 'optional: skip it';
        return 1;
    }


    if ($self->required && !$value) {
        carp 'required but empty!';
        return;
    }

    if ($value && ref $value && ref $value ne 'ARRAY') {
        carp '$value should be SCALAR or ARRAYREF';
        return;
    }

    $value = [$value] if not ref $value eq 'ARRAY';

    for my $v (@$value) {
        if (!$self->type->check($v)) {
            carp 'check() failed';
            return;
        }
        elsif ($self->regex && ($v !~ /${ $self->regex }/)) {
            warn "$v == ${ $self->regex }";
            carp 'regex failed';
            return;
        }

        if ($self->type->in) {
            $self->value($self->type->in->($self->value));
        }
    }

    1;
}

1;

__END__

=pod

=head1 NAME

Raisin::Param

=head1 SYNOPSYS

    use Raisin::Param

=head1 DESCRIPTION

Raisin Param

=over

=cut
