package RESTApp;

use strict;
use warnings;

use feature 'say';

use FindBin '$Bin';
use lib ("$Bin/../lib", "$Bin/../../../lib");

use Raisin::API;

plugin 'Swagger', enable => 'CORS';
plugin 'Logger', outputs => [['Screen', min_level => 'debug']];

swagger_setup(
    title => 'Users & hosts API',
    description => 'An example of API documentation.',

    contact => {
        name => 'Artur Khabibullin',
        url => 'http://github.com/khrt',
        email => 'rtkh@cpan.org',
    },

    license => {
        name => 'Perl license',
        url => 'http://dev.perl.org/licenses/',
    },
);

#before sub {
#    my $self = shift;
#    say 'Before ' . $self->req->method . q{ } . $self->req->path;
#};

mount 'RESTApp::Host';
mount 'RESTApp::User';

# Utils
sub paginate {
    my ($data, $params) = @_;

    my $max_count = scalar(@$data) - 1;
    my $start = _return_max($params->{start}, $max_count);
    my $count = _return_max($params->{count}, $max_count);

    my @slice = @$data[$start .. $count];
    \@slice;
}

sub _return_max {
    my ($value, $max) = @_;
    $value > $max ? $max : $value;
}

1;
