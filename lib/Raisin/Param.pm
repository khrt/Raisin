package Raisin::Param;

use strict;
use warnings;

use Carp;
use Raisin::Attributes;

my @ATTRS = qw(name type default regex desc in);
my @LOCATION = qw/path formData body header query/;

has 'named';
has 'required';

has 'default';
has 'name';
has 'type';
has 'regex';
has 'desc';

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $self->{named} = $args{named} || 0;
    $self->{required} = $args{type} =~ /^require(s|d)$/ ? 1 : 0;

    return unless $self->_parse($args{spec});

    $self;
}

sub _parse {
    my ($self, $spec) = @_;

    $self->{$_} = $spec->{$_} for @ATTRS[0 .. $#ATTRS-1];

    if ($spec->{in}) {
        return unless $self->in($spec->{in});
    }

    return 1;
}

sub in {
    my ($self, $value) = @_;

    if (defined $value) {
        unless (grep { $value eq $_ } @LOCATION) {
            Raisin::log(warn => '`%s` should be one of: %s',
                $self->name, join ', ', @LOCATION);
            return;
        }

        $self->{in} = $value;
    }

    $self->{in};
}

sub validate {
    my ($self, $ref_value, $quiet) = @_;

    # Required
    # Only optional parameters can has default value
    if ($self->required && !defined($$ref_value)) {
        Raisin::log(warn => '`%s` is required', $self->name) unless $quiet;
        return;
    }

    # Optional and empty
    if (!$self->required && !defined($$ref_value)) {
        Raisin::log(info => '`%s` optional and empty', $self->name);
        return 1;
    }

    # Type check
    eval { $$ref_value = $self->type->($$ref_value) };
    if (my $e = $@) {
        unless ($quiet) {
            Raisin::log(warn => 'Param `%s` didn\'t pass constraint `%s` with value "%s"',
                $self->name, $self->type->name, $$ref_value);
        }
        return;
    }

    # Parameter check
    if ($self->regex && $$ref_value !~ $self->regex) {
        unless ($quiet) {
            Raisin::log(warn => 'Param `%s` didn\'t match regex `%s` with value "%s"',
                $self->name, $self->regex, $$ref_value);
        }
        return;
    }

    1;
}

1;

__END__

=head1 NAME

Raisin::Param - Parameter class for Raisin.

=head1 DESCRIPTION

Parameter class for L<Raisin>. Validates request paramters.

=head3 default

Returns default value if exists or C<undef>.

=head3 desc

Returns parameter description.

=head3 name

Returns parameter name.

=head3 named

Returns C<true> if it's path parameter.

=head3 regex

Return paramter regex if exists or C<undef>.

=head3 required { shift->{required} }

Returns C<true> if it's required parameter.

=head3 type

Returns parameter type object.

=head3 in

Returns the location of the parameter: B<query, header, path, formData, body>.

=head3 validate

Process and validate parameter. Takes B<reference> as the input paramter.

    $p->validate(\$value);

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
