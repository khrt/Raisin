package Raisin::Request;

use strict;
use warnings;

use base 'Plack::Request';

sub new {
    my ($class, $env) = @_;
    my $self = $class->SUPER::new($env);
    $self;
}


1;
