package Rapp;

use strict;
use warnings;

use FindBin '$Bin';
use lib ("$Bin/../lib", "$Bin/../../../lib");

use Raisin::DSL;

#before sub {
#    error('FORBIDDEN', 401) if not authenticated
#}

api_format 'YAML';

mount 'Rapp::User';
mount 'Rapp::Host';

#require Rapp::Host;
#require Rapp::User;

1;
