package Raisin::Param;

use strict;
use warnings;

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

sub default { shift->{default} }
sub name { shift->{name} }
sub required { shift->{required} }
sub type { shift->{type} }

sub regex {

}

sub validate {

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
