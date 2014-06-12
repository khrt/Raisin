package UseCase::Host;

use strict;
use warnings;

use List::Util qw(max);

# Storage
my %HOSTS = (
    1 => {
        name => 'deathstart.com',
        user_id => 1,
        state => 'active',
    },
    2 => {
        name => 'jedi.com',
        user_id => 2,
        state => 'active',
    },
    3 => {
        name => 'naboo.com',
        user_id => 2,
        state => 'inactive',
    },
);

sub list {
    my %params = @_;
    map { { id => $_, %{ $HOSTS{$_} } } } sort { $a <=> $b } keys %HOSTS;
}

sub create {
    my %params = @_;

    my $id = max(keys %HOSTS) + 1;
    $HOSTS{$id} = %params;

    $id;
}

sub show {
    my $id = shift;
    $HOSTS{$id};
}

sub edit {
    my ($id, %params) = @_;

    foreach my $p (keys %params) {
        $HOSTS{$id}{$p} = $params{$p};
    }

    $HOSTS{$id};
}

sub delete {
    my $id = shift;
    delete $HOSTS{$id};
    1;
}

1;
