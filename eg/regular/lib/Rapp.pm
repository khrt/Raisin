package Rapp;

use strict;
use warnings;

use lib "$FindBin::Bin/../../lib"; # ->Raisin/lib

use Raisin::DSL;

use Rapp::Host;
use Rapp::User;

#before sub {
#    error('FORBIDDEN', 401) if not authenticated
#}

mount 'Rapp::Host' => 'v2';
mount 'Rapp::User';

1;
