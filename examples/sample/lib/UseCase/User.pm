package UseCase::User;

use strict;
use warnings;

use List::Util qw(max);

# Storage
my %USERS = (
    1 => {
        name => 'Darth Wader',
        password => 'empire',
        email => 'darth@deathstar.com',
    },
    2 => {
        name => 'Luke Skywalker',
        password => 'qwerty',
        email => 'l.skywalker@jedi.com',
    },
);

sub list {
    my %params = @_;
    map { { id => $_, %{ $USERS{$_} } } } sort { $a <=> $b } keys %USERS;
}

sub create {
    my %params = @_;

    my $id = max(keys %USERS) + 1;
    $USERS{$id} = %params;

    $id;
}

sub show {
    my $id = shift;
    $USERS{$id};
}

sub edit {
    my ($id, %params) = @_;

    foreach my $p (keys %params) {
        $USERS{$id}{$p} = $params{$p};
    }

    $USERS{$id};
}

sub delete {
    my $id = shift;
    delete $USERS{$id};
    1;
}

sub bump {
    my $id = shift;
    $USERS{$id}{bumped}++;
}

1;
