package Raisin::Entity;

use strict;
use warnings;

use Carp;
use Scalar::Util qw(blessed);

use parent 'Exporter';

our @EXPORT = qw(expose);

my $SUBNAME_PREFIX = 'Raisin::Entity::Nested';
my @SUBNAME;

sub expose {
    my ($name, @params) = @_;

    my $runtime;
    if (scalar(@params) % 2 && ref($params[-1]) eq 'CODE') {
        $runtime = delete $params[-1];
    }

    my %params = @params;
    my %settings = (
        alias         => $params{as},
        condition     => $params{if},
        name          => $name,
        runtime       => $runtime,
        using         => $params{using},
    );

    #documentation => $params{documentation}, # TODO

    my $class = caller;
    $class = $SUBNAME_PREFIX . '::' . $SUBNAME[-1] if scalar @SUBNAME;

    {
        no strict 'refs';
        push @{ "${class}::EXPOSE" }, \%settings;
    }

    return $class if scalar @SUBNAME;
    return;
}

sub compile {
    my ($self, $entity, $data) = @_;

    my @expose = do {
        no strict 'refs';
        @{"${entity}::EXPOSE"};
    };

    @expose = _make_exposition($data) unless @expose;

    my $result;

    # Rose::DB::Object::Iterator, DBIx::Class::ResultSet
    # Array
    #
    # Hash, Rose::DB::Object, DBIx::Class::Core
    #
    # Scalar, everything else

    if (blessed($data) && $data->can('next'))
    {
        while (my $i = $data->next) {
            push @$result, _compile_column($entity, $i, \@expose);
        }
    }
    elsif (ref($data) eq 'ARRAY') {
        for my $i (@$data) {
            push @$result, _compile_column($entity, $i, \@expose);
        }
    }
    elsif (ref($data) eq 'HASH'
           || (blessed($data)
               && (   $data->isa('Rose::DB::Object')
                   || $data->isa('DBIx::Class::Core'))))
    {
        $result = _compile_column($entity, $data, \@expose);
    }
    else {
        $result = $data;
    }

    $result;
}

sub _compile_column {
    my ($entity, $data, $settings) = @_;
    my %result;

    for my $i (@$settings) {
        next if $i->{condition} && !$i->{condition}->($data);

        my $column = $i->{name};

        my $key = $i->{alias} || $i->{name};
        my $value = do {
            if (my $runtime = $i->{runtime}) {
                push @SUBNAME, "${entity}::$column";
                my $retval = $runtime->($data);
                pop @SUBNAME;

                if ($retval && !ref($retval) && $retval =~ /^Raisin::Entity::Nested::/) {
                    $retval = __PACKAGE__->compile($retval, $data);
                }

                $retval;
            }
            elsif (my $e = $i->{using}) {
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
                keys %{ $data->first->columns_info }; # -> HASH
            }
            elsif ($data->isa('DBIx::Class::Core')) {
                keys %{ $data->columns_info }; # -> HASH
            }
            elsif ($data->isa('Rose::DB::Object')) {
                $data->meta->column_names; # -> ARRAY
            }
            elsif ($data->isa('Rose::DB::Object::Iterator')) {
                croak 'Rose::DB::Object::Iterator isn\'t supported';
            }
        }
        elsif (ref($data) eq 'ARRAY') {
            if (blessed($data->[0]) && $data->[0]->isa('Rose::DB::Object')) {
                $data->[0]->meta->column_names; # -> ARRAY
            }
            else {
                keys %{ $data->[0] }; # -> HASH
            }
        }
        elsif (ref($data) eq 'HASH') {
            keys %$data; # -> HASH
        }
    };

    return if not @columns;
    map { { name => $_ } } @columns;
}

1;

__END__

=head1 NAME

Raisin::Entity - Simple facade to use with your API.

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
        expose('phone');
        expose('address', using => 'API::Address');
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

=head3 Documentation

NOT IMPLEMENTED!

Expose documentation with the field.
Is used in a L<Raisin::Plugin::Swagger> API documentation systems.

    expose 'name', documentation => { type => 'String', desc => 'Artists name' };

All available keys for C<documentation> you could find in the L<Raisin::Plugin::Swagger>.

=head2 compile

Compile an entity.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
