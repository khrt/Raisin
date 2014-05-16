package Rapp;

use strict;
use warnings;

use FindBin '$Bin';
use lib ("$Bin/../lib", "$Bin/../../../lib");

use Raisin::API;

api_format 'json';
plugin 'APIDocs';

before sub {
#    my $self = shift;
#    say 'before each route?';
#    say $self->req->method;
#    say $self->req->path;
    #error('FORBIDDEN', 401) if not authenticated
};

mount 'Rapp::Host';
mount 'Rapp::User';
#require Rapp::Host;
#require Rapp::User;

1;
