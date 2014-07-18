package RESTApp::Host;

use strict;
use warnings;

use Raisin::API;
use UseCase::Host;

use Types::Standard qw(Int Str);

resource host => sub {
    params [
        optional => { name => 'start', type => Int, default => 0, desc => 'Pager start' },
        optional => { name => 'count', type => Int, default => 10, desc => 'Pager count' },
    ],
    desc => 'List hosts',
    get => sub {
        my $params = shift;
        my @hosts = UseCase::Host::list(%$params);
        { data => paginate(\@hosts, $params) }
    };

    params [
        required => { name => 'name', type => Str, desc => 'Host name' },
        required => { name => 'user_id', type => Int, desc => 'Host owner' },
        optional => { name => 'state', type => Str, desc => 'Host state' }
    ],
    desc => 'Create new host',
    post => sub {
        my $params = shift;
        { success => UseCase::Host::create(%$params) }
    };

    route_param id => Int,
    sub {
        desc 'Show host',
        get => sub {
            my $params = shift;
            { data => UseCase::Host::show($params->{id}) }
        };

        params [
            required => { name => 'state', type => Str, desc => 'Host state' },
        ],
        desc => 'Edit host',
        put => sub {
            my $params = shift;
            { data => UseCase::Host::edit($params->{id}, %$params) }
        };

        desc 'Delete host',
        del => sub {
            my $params = shift;
            { success => UseCase::Host::delete($params->{id}) }
        }
    };
};

1;
