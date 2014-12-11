package RESTApp::Host;

use strict;
use warnings;

use Raisin::API;
use UseCase::Host;

use Types::Standard qw(Int Str);

resource host => sub {
    desc 'List hosts';
    params(
        optional => { name => 'start', type => Int, default => 0, desc => 'Pager start' },
        optional => { name => 'count', type => Int, default => 10, desc => 'Pager count' },
    );
    get sub {
        my $params = shift;
        my @hosts = UseCase::Host::list(%$params);
        { data => paginate(\@hosts, $params) }
    };

    desc 'Create new host';
    params(
        required => { name => 'name', type => Str, desc => 'Host name' },
        required => { name => 'user_id', type => Int, desc => 'Host owner' },
        optional => { name => 'state', type => Str, desc => 'Host state' }
    );
    post sub {
        my $params = shift;
        { success => UseCase::Host::create(%$params) }
    };

    params(
        requires => { name => 'id', type => Int }
    );
    route_param id => sub {
        desc 'Show host';
        get sub {
            my $params = shift;
            { data => UseCase::Host::show($params->{id}) }
        };

        desc 'Edit host';
        params(
            required => { name => 'state', type => Str, desc => 'Host state' },
        );
        put sub {
            my $params = shift;
            { data => UseCase::Host::edit($params->{id}, %$params) }
        };

        desc 'Delete host';
        del sub {
            my $params = shift;
            { success => UseCase::Host::remove($params->{id}) }
        }
    };
};

1;
