package Raisin::Plugin;

use strict;
use warnings;

use Carp;

sub new {
    my ($class, $app) = @_;
    my $self = bless {}, $class;
    $self->{app} = $app;
    $self;
}

sub app { shift->{app} }

sub build {
    my ($self, %args) = @_;
}

sub register {
    my ($self, %items) = @_;

    while (my ($name, $item) = each %items) {
        no strict 'refs';
        #no warnings 'redefine';

        my $class = ref $self->app;
        my $caller = $self->app->{caller};

        my $glob = "${class}::${name}";
        my $app_glob = "${caller}::${name}";

        if ($self->app->can($name)) {
            croak "Redefining of $glob not allowed";
        }

        if (ref $item eq 'CODE') {
            *{$glob} = $item;
            *{$app_glob} = $item;
        }
        else {
            $self->app->{$name} = $item;
            *{$glob} = sub { shift->{$name} };
        }
    }
}

1;

__END__

=head1 NAME

Raisin::Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
