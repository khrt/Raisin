package Raisin::Encoder::JSON;

use strict;
use warnings;

use JSON::MaybeXS qw();

my $json = JSON::MaybeXS->new(utf8 => 1);

sub detectable_by { [qw(application/json text/x-json text/json json)] }

sub content_type { 'application/json' }

sub serialize { $json->allow_blessed->convert_blessed->encode($_[1]) }

sub deserialize { $json->allow_blessed->convert_blessed->decode($_[1]) }

1;

__END__

=head1 NAME

Raisin::Encoder::JSON - JSON serialization plugin for Raisin.

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
