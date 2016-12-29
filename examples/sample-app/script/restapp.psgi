#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use Plack::Builder;

use lib "$Bin/../lib";

use RESTApp;

builder {
    mount '/api' => RESTApp->new;
};
