package Raisin::Entity::Object;

use strict;
use warnings;

use Raisin::Attributes;
use Types::Standard qw/Any/;

has 'name';
has 'runtime';
has 'using';

# Needed for OpenAPI only
has 'required' => 1;

sub new {
    my ($class, $name, @params) = @_;

    if (scalar(@params) % 2 && ref($params[-1]) eq 'CODE') {
        splice @params, -1, 0, 'runtime';
    }

    bless { name => $name, @params }, $class;
}

sub alias { shift->{as} }
sub condition { shift->{if} }

sub type { shift->{type} || Any }

sub display_name {
    my $self = shift;
    $self->alias || $self->name;
}

1;
