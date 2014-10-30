package Raisin::Entity;

use strict;
use warnings;

use parent 'Exporter';

use Carp;
use DDP;
use feature 'say';

our @EXPORT = qw(present);

sub import {
    my $class = shift;
    $class->export_to_level(1, @_);
}

my %STORAGE;

sub present {
    my ($name, $data, %params) = @_;

#    p $name;
#    p $data;
#    p %params;

    my $proc_data;

    # DBIx::Class
    if (ref($data) eq 'DBIx::Class::ResultSet') {
        while (my $i = $data->next) {

            my %d = map { $_ => $i->$_ } keys %{ $data->result_source->columns_info };
            push @$proc_data, \%d;

        }
    }
    elsif (ref($data) eq 'ARRAY') {
        # TODO:
    }
    elsif (!ref($data)) {
        $proc_data = $data;
    }

    $STORAGE{$name} = $proc_data;

    \%STORAGE;
}

sub expose {
    my ($self, $name, $params) = @_;

    # expose 'user_name'
    # expose 'text', documentation { ... }
    # expose 'ip', if { ... }
    # expose 'contact_info', sub {
    #   expose :phone
    #   expose :address, using Entity::Address
    # }
    # expose :digest, sub {
    #   my $item = shift;
    #   hexhash($item->name);
    # }
    # expose 'user_name', as 'name';

}

sub documentation {
    my $doc = shift;
}

#sub if(&) {
#    my $sub = shift;
#
#}

sub as {
    my $alias = shift;
}

1;

__END__

=head1 NAME

Raisin::Entity - 

=head1 DESCRIPTION

=head1 KEYWORDS

=head2 expose

=cut
