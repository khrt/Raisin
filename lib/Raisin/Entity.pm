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
            push @$result, _compile_column($i, \@expose);
        }
    }
    elsif (ref($data) eq 'ARRAY') {
        for my $i (@$data) {
            push @$result, _compile_column($i, \@expose);
        }
    }
    elsif (ref($data) eq 'HASH'
           || (blessed($data)
               && (   $data->isa('Rose::DB::Object')
                   || $data->isa('DBIx::Class::Core'))))
    {
        $result = _compile_column($data, \@expose);
    }
    else {
        $result = $data;
    }

    $result;
}

sub _compile_column {
    my ($data, $settings) = @_;

    my %result = map {
        my $column = $_->{name};
        my $key = $_->{alias} || $_->{name};

        my $value = do {
            if (my $runtime = $_->{runtime}) {
                $runtime->($data);
            }
            elsif (my $entity = $_->{using}) {
                my $inner_data = blessed($data) ? $data->$column : $data->{$column};
                $entity->compile($inner_data);
            }
            else {
                blessed($data) ? $data->$column : $data->{$column};
            }
        };

        if (my $condition = $_->{condition}) {
            # TODO:
            # value has to be evaluatead each time
            # despite of condition which can be false
            $condition->($data) ? ($key => $value) : ();
        }
        else {
            ($key => $value);
        }
    } @$settings;

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

Raisin::Entity - Simple Facade to use with your API.

=head1 SYNOPSIS

    package MusicApp::Entity::Artist;

    use strict;
    use warnings;

    use parent 'Raisin::Entity';

    __PACKAGE__->expose('id');
    __PACKAGE__->expose('name', as => 'artist');
    __PACKAGE__->expose('website', if => sub {
        my $artist = shift;
        $artist->website;
    });
    __PACKAGE__->expose('albums', using => 'MusicApp::Entity::Album');
    __PACKAGE__->expose('hash', sub {
        my $artist = shift;
        my $hash = 0;
        my $name = blessed($artist) ? $artist->name : $artist->{name};
        foreach (split //, $name) {
            $hash = $hash * 42 + ord($_);
        }
        $hash;
    });

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

    __PACKAGE__->expose('id');

=head3 Exposing with a presenter

Use C<using> to expose field with a presenter.

    __PACKAGE__->expose('albums', using => 'MusicApp::Entity::Album');

=head3 Conditional exposure

You can use C<if> to expose fields conditionally.

    __PACKAGE__->expose('website', if => sub {
        my $artist = shift;
        blessed($artist) && $artist->can('website');
    });

=head3 Nested exposure

NOT IMPLEMENTED!

Supply a block to define a hash using nested exposures.

    __PACKAGE__->expose('contact_info', sub {
        __PACKAGE__->expose('phone');
        __PACKAGE__->expose('address', using => 'API::Address');
    });

=head3 Runtime exposure

Use a subroutine to evaluate exposure at runtime.

    __PACKAGE__->expose('hash', sub {
        my $artist = shift;
        my $hash;
        foreach (split //, $artist->name) {
            $hash = $hash * 42 + ord($_);
        }
        $hash;
    });

=head3 Aliases exposure

Expose under a different name with C<as>.

    __PACKAGE__->expose('name', as => 'artist');

=head3 Documentation

NOT IMPLEMENTED!

Expose documentation with the field.
Gets bubbled up when used with L<Raisin::Plugin::Swagger> API documentation systems.

    __PACKAGE__->expose(
        'name', documentation => { type => 'String', desc => 'Artists name' }
    );

=head2 compile

Compile an entity.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
