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

    if (blessed($data)) {
        if ($data->isa('DBIx::Class')) {
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
            croak 'NOT IMPLEMENTED';
        }
    }
    else {
        @expose = _make_exposition($data) unless @expose;

        if (ref($data) eq 'ARRAY') {
            for my $i (@$data) {
                push @$result, _compile_column($i, \@expose);
            }
        }
        elsif (ref($data) eq 'HASH') {
            $result = _compile_column($data, \@expose);
        }
        else {
            $result = $data;
        }
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
                my $inner_data = $data->{$column};
                $entity->compile($inner_data);
            }
            else {
                $data->{$column};
            }
        };

        if (my $condition = $_->{condition}) {
            # TODO: it has to evaluate value each time despite of condition can be falsy
            $condition->($data) ? ($key => $value) : ();
        }
        else {
            ($key => $value);
        }
    } @$settings;

    \%result;
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
            # TODO: it has to evaluate value each time despite of condition can be falsy
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

    my @columns_info = do {
        if (ref($data) eq 'ARRAY') {
            keys $data->[0];
        }
        elsif (ref($data) eq 'HASH') {
            keys $data;
        }
    };

    map { { name => $_ } } @columns_info;
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

=head1 SYNOPSIS

    package MusicApp::Entity::Artist;

    use strict;
    use warnings;

    use parent 'Raisin::Entity';

    __PACKAGE__->expose('id');
    __PACKAGE__->expose('name', as => 'artist');
    __PACKAGE__->expose('albums', using => 'MusicApp::Entity::Album');

    1;

=head1 DESCRIPTION

Supports L<DBIx::Class>
and basic Perl data structures like C<SCALAR>, C<ARRAY> & C<HASH>.

=head1 METHODS

=head2 expose

Define a fields that will be exposed.

The field lookup requests specified name

=over

=item * as an object method if object is a L<DBIx::Class> or a L<Rose::DB::Object>;

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
            $hash = $hash * 33 + ord($_);
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

=cut
