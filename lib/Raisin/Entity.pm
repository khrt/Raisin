#!perl
#PODNAME: Raisin::Entity
#ABSTRACT: A simple facade to use with your API

use strict;
use warnings;

package Raisin::Entity;

use parent 'Exporter';

use Carp;
use Scalar::Util qw(blessed);
use Types::Standard qw/HashRef/;

use Raisin::Entity::Object;

our @EXPORT = qw(expose);

my @SUBNAME;

sub import {
    {
        no strict 'refs';

        my $class = caller;

        *{ "${class}::name" } = sub { $class };
        # A kind of a workaround for OpenAPI
        # Every entity has a HashRef type even if it is not, so it could cause
        # issues for users in OpenAPI specification.
        *{ "${class}::type" } = sub { HashRef };
        *{ "${class}::enclosed" } = sub {
            no strict 'refs';
            \@{ "${class}::EXPOSE" };
        };
    }

    Raisin::Entity->export_to_level(1, @_);
}

sub expose {
    my ($name, @params) = @_;

    my $class = caller;
    if (scalar @SUBNAME) {
        $class = 'Raisin::Entity::Nested::' . join('', @SUBNAME);
    }

    {
        no strict 'refs';
        push @{ "${class}::EXPOSE" }, Raisin::Entity::Object->new($name, @params);
    }

    return $class if scalar @SUBNAME;
}

sub compile {
    my ($self, $entity, $data) = @_;

    my @expose = do {
        no strict 'refs';
        @{ "${entity}::EXPOSE" };
    };

    @expose = _make_exposition($data) unless @expose;
    return $data unless @expose;

    my $result;

    # Rose::DB::Object::Iterator, DBIx::Class::ResultSet
    if (blessed($data) && $data->can('next')) {
        while (my $i = $data->next) {
            push @$result, _compile_column($entity, $i, \@expose);
        }

        $result = [] unless $result;
    }
    # Array
    elsif (ref($data) eq 'ARRAY') {
        for my $i (@$data) {
            push @$result, _compile_column($entity, $i, \@expose);
        }

        $result = [] unless $result;
    }
    # Hash, Rose::DB::Object, DBIx::Class::Core
    elsif (ref($data) eq 'HASH'
           || (blessed($data)
               && (   $data->isa('Rose::DB::Object')
                   || $data->isa('DBIx::Class::Core'))))
    {
        $result = _compile_column($entity, $data, \@expose);
    }
    # Scalar, everything else
    else {
        $result = $data;
    }

    $result;
}

sub _compile_column {
    my ($entity, $data, $settings) = @_;
    my %result;

    for my $obj (@$settings) {

        next if blessed($obj) && $obj->condition && !$obj->condition->($data);

        my $column = blessed($obj) ? $obj->name : $obj->{name};

        my $key    = blessed($obj) ? $obj->display_name : $obj->{name};
        my $value = do {
            if (blessed($obj) and my $runtime = $obj->runtime) {

                push @SUBNAME, "${entity}::$column";
                my $retval = $runtime->($data);
                pop @SUBNAME;

                if ($retval && !ref($retval) && $retval =~ /^Raisin::Entity::Nested::/) {
                    $retval = __PACKAGE__->compile($retval, $data);
                }

                $retval;
            }
            elsif (blessed($obj) and my $e = $obj->using) {
                my $in = blessed($data) ? $data->$column : $data->{$column};
                __PACKAGE__->compile($e, $in);
            }
            else {
                blessed($data) ? $data->$column : $data->{$column};
            }
        };

        $result{$key} = $value;
    }

    \%result;
}

sub _make_exposition {
    my $data = shift;

    my @columns = do {
        if (blessed($data)) {
            if ($data->isa('DBIx::Class::ResultSet')) {
                keys %{ $data->first->columns_info };
            }
            elsif ($data->isa('DBIx::Class::Core')) {
                keys %{ $data->columns_info };
            }
            elsif ($data->isa('Rose::DB::Object')) {
                $data->meta->column_names;
            }
            elsif ($data->isa('Rose::DB::Object::Iterator')) {
                croak 'Rose::DB::Object::Iterator isn\'t supported';
            }
        }
        elsif (ref($data) eq 'ARRAY') {
            if (blessed($data->[0]) && $data->[0]->isa('Rose::DB::Object')) {
                $data->[0]->meta->column_names;
            }
            else {
                ();
            }
        }
        elsif (ref($data) eq 'HASH') {
            ();
        }
    };

    return if not @columns;
    map { { name => $_ } } @columns;
}

1;

__END__

=head1 SYNOPSIS

    package MusicApp::Entity::Artist;

    use strict;
    use warnings;

    use Raisin::Entity;

    expose 'id';
    expose 'name', as => 'artist';
    expose 'website', if => sub {
        my $artist = shift;
        $artist->website;
    };
    expose 'albums', using => 'MusicApp::Entity::Album';
    expose 'hash', sub {
        my $artist = shift;
        my $hash = 0;
        my $name = blessed($artist) ? $artist->name : $artist->{name};
        foreach (split //, $name) {
            $hash = $hash * 42 + ord($_);
        }
        $hash;
    };

    1;

=head1 DESCRIPTION

Supports L<DBIx::Class>, L<Rose::DB::Object>
and basic Perl data structures like C<SCALAR>, C<ARRAY> & C<HASH>.

=head1 METHODS

=head2 expose

Define a fields that will be exposed.

The field lookup requests specified name

=over

=item * as an object method if it is a L<DBIx::Class> or a L<Rose::DB::Object>;

=item * as a hash key;

=item * die.

=back

=head3 Basic exposure

    expose 'id';

=head3 Exposing with a presenter

Use C<using> to expose a field with a presenter.

    expose 'albums', using => 'MusicApp::Entity::Album';

=head3 Conditional exposure

You can use C<if> to expose fields conditionally.

    expose 'website', if => sub {
        my $artist = shift;
        blessed($artist) && $artist->can('website');
    };

=head3 Nested exposure

Supply a block to define a hash using nested exposures.

    expose 'contact_info', sub {
        expose 'phone';
        expose 'address', using => 'API::Address';
    };

=head3 Runtime exposure

Use a subroutine to evaluate exposure at runtime.

    expose 'hash', sub {
        my $artist = shift;
        my $hash;
        foreach (split //, $artist->name) {
            $hash = $hash * 42 + ord($_);
        }
        $hash;
    };

=head3 Aliases exposure

Expose under an alias with C<as>.

    expose 'name', as => 'artist';

=head3 Type

    expose 'name', documentation => { type => 'String', desc => 'Artists name' };

=head2 OpenAPI

OpenAPI compatible specification generates automatically if OpenAPI/Swagger
plugin enabled.

=cut
