#!perl
#PODNAME: Raisin::Encoder::JSON
#ABSTRACT: JSON serialization plugin for Raisin.

use strict;
use warnings;

package Raisin::Encoder::JSON;

use JSON::MaybeXS qw();

my $json = JSON::MaybeXS->new(utf8 => 1);

sub detectable_by { [qw(application/json text/x-json text/json json)] }

sub content_type { 'application/json; charset=utf-8' }

sub serialize { $json->allow_blessed->convert_blessed->encode($_[1]) }

sub deserialize { $json->allow_blessed->convert_blessed->decode($_[1]) }

1;

__END__

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=cut
