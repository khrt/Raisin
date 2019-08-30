package Raisin::Util;

use strict;
use warnings;

use Plack::Util;

sub make_tag_from_path {
    my $path = shift;
    my @c = (split '/', $path);
    return 'none' unless scalar @c;
    $c[-2] || $c[1];
}

sub iterate_params {
    my $params = shift;
    my $index = 0;

    return sub {
        $index += 2;
        ($params->[$index-2], $params->[$index-1]);
    };
}

1;

__END__

=head1 NAME

Raisin::Util - Utility subroutine for Raisin.

=head1 FUNCTIONS

=head2 make_tag_from_path

Splits a path and returns the first part of it.

=head2 iterate_params

Iterates over route parameters.

=head1 AUTHOR

Artur Khabibullin - rtkh E<lt>atE<gt> cpan.org

=head1 LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.

=cut
