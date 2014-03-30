#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use Plack::Builder;

use lib ("$Bin/../lib", "$Bin/../../../lib");

use Rapp;

builder {
    mount '/api' => Rapp->new;
};
