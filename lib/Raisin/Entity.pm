package Raisin::Entity;

use strict;
use warnings;

use Carp;
use Scalar::Util qw(blessed);

sub expose {
    my ($class, $name, @params) = @_;

    my $runtime;
    if (scalar(@params) % 2 && ref($params[-1]) eq 'CODE') {
        $runtime = delete $params[-1];
    }

    my %params = @params;

    {
        no strict 'refs';
        push @{ "${class}::EXPOSE" }, {
            alias         => $params{as},
            condition     => $params{if},
            documentation => $params{documentation},
            name          => $name,
            runtime       => $runtime,
            using         => $params{using},
        };
    }

    return;
}

sub compile {
    my ($class, $data) = @_;

    my @expose = do {
        no strict 'refs';
        @{"${class}::EXPOSE"};
    };

    my $result;

    if (blessed($data) && $data->isa('DBIx::Class')) {
        @expose = _make_exposition_from_dbix_class($data) unless @expose;

        if ($data->isa('DBIx::Class::ResultSet')) {
            while (my $i = $data->next) {
                push @$result, _compile_dbix_class_column($i, \@expose);
            }
        }
        elsif ($data->isa('DBIx::Class::Core')) {
            $result = _compile_dbix_class_column($data, \@expose);
        }
    }
    else {
        $result = $data;
    }

    $result;
}

sub _compile_dbix_class_column {
    my ($data, $settings) = @_;

    my %result = map {
        my $column = $_->{name};
        my $key = $_->{alias} || $_->{name};

        my $value = do {
            if (my $runtime = $_->{runtime}) {
                $runtime->($data);
            }
            elsif (my $entity = $_->{using}) {
                my $inner_data = $data->$column;
                $entity->compile($inner_data);
            }
            else {
                $data->$column;
            }
        };

        if (my $condition = $_->{condition}) {
            $condition->($data) ? ($key => $value) : ();
        }
        else {
            ($key => $value);
        }
    } @$settings;

    \%result;
}

sub _make_exposition_from_dbix_class {
    my $data = shift;

    my $columns_info = do {
        if ($data->isa('DBIx::Class::ResultSet')) {
            $data->first->columns_info;
        }
        elsif ($data->isa('DBIx::Class::Core')) {
            $data->columns_info;
        }
    };

    map { { name => $_ } } keys %$columns_info;
}

1;

__END__

=head1 NAME

Raisin::Entity - simple Facade to use with your API.

=head1 DESCRIPTION

Supports only L<DBIx::Class>
and basic Perl data structures like C<SCALAR>, C<ARRAY>, C<HASH>.

=head1 METHODS

=head2 expose

    expose 'user_name'
    ?expose 'text', documentation => { ... }
    expose 'ip', if => { ... }
    ?expose 'contact_info', sub {
    ?    expose :phone
    ?    expose :fax
    ?}
    expose 'address', using => 'Entity::Address'
    expose 'digest', sub {
        my $item = shift;
        hexhash($item->name);
    }
    expose 'user_name', as => 'name';

=cut
