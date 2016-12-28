package Raisin::Entity::Object;

use strict;
use warnings;

use Plack::Util::Accessor qw(
    desc
    name
    runtime
    using
);
use Types::Standard qw(Any ArrayRef HashRef);

sub new {
    my ($class, $name, @params) = @_;

    if (scalar(@params) % 2 && ref($params[-1]) eq 'CODE') {
        splice @params, -1, 0, 'runtime';
    }

    bless { name => $name, @params }, $class;
}

sub required { 1 }
sub alias { shift->{as} }
sub condition { shift->{if} }

sub type {
    my $self = shift;

    my $type = do {
        if ($self->{type}) {
            $self->{type};
        }
        elsif ($self->using) {
            ArrayRef[HashRef];
        }
        else {
            Any;
        }
    };

    $type;
}

sub display_name {
    my $self = shift;
    $self->alias || $self->name;
}

1;

__END__

=head1 NAME

Raisin::Entity::Object - An expose object.

=head1 DESCRIPTION

An internal object used in L<Raisin::Plugin::Swagger> and L<Raisin::Entity>.

=head1 METHODS

=head2 name

A parameter's name.

=head2 runtime

A parameter's C<CODE> reference.

=head2 using

A link to other L<Raisin::Entity> which will be used to expose.

=head2 required

Made for compatibility with L<Raisin::Param>. Always returns C<true>.

=head2 alias

A parameter's alias.

=head2 condition

A parameter's C<CODE> reference which is used to evaluate a condition.

=head2 type

A parameter's type.

=head2 display_name

Displays a parameter's L<Raisin::Entity::Object/alias> if set
or L<Raisin::Entity::Object/name> otherwise.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
