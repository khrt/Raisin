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
    my ($self, $kind, $required, $options) = @_;

    $self->{required} = $required eq 'required' ? 1 : 0;
    $self->{named} = $kind eq 'named' ? 1 : 0;
    @$self{qw(name type default regex)} = @$options;
}

sub default { $_[0]->{default} || $_[0]->type->default }
sub name { shift->{name} }
sub regex { $_[0]->{regex} || $_[0]->type->regex }
sub required { shift->{required} }
sub named { shift->{named} }
sub type { shift->{type} }

sub value {
    my ($self, $value) = @_;
    $self->{value} = $value if defined $value;
    $self->{value} // $self->default // $self->type->default // '';
}

sub validate {
    my ($self, $value) = @_;

    # TODO Don't working
    if (!$value && $self->value) {
        carp "$self->{name} use default value";
        return 1;
    }

    if (!$value && !$self->required) {
#        carp "$self->{name} optional: skip it";
        return 1;
    }


    if ($self->required && !$value) {
        carp "$self->{name} required but empty!";
        return;
    }

    if ($value && ref $value && ref $value ne 'ARRAY') {
        carp "$self->{name} \$value should be SCALAR or ARRAYREF";
        return;
    }

    $value = [$value] if not ref $value eq 'ARRAY';

    for my $v (@$value) {
        if (!$self->type->check($v)) {
            carp "$self->{name} check() failed";
            return;
        }
        elsif ($self->{regex} && ($v !~ /$self->{regex}/)) {
            carp "$self->{name} regex failed [$v !~ $self->{regex}]";
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
