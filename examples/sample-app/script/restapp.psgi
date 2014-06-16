#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use Plack::Builder;

# Include lib and Raisin/lib
use lib ("$Bin/../lib", "$Bin/../../../lib");

use RESTApp;

builder {
    mount '/api' => RESTApp->new;
};
