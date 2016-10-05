package RESTApp::Host;

use strict;
use warnings;

use Raisin::API;
use UseCase::Host;

use Types::Standard qw(Int Str);

desc 'Operations about host';
resource hosts => sub {
    summary 'List hosts';
    params(
        optional('start', type => Int, default => 0, desc => 'Pager start'),
        optional('count', type => Int, default => 10, desc => 'Pager count'),
    );
    get sub {
        my $params = shift;
        my @hosts = UseCase::Host::list(%$params);
        { data => RESTApp::paginate(\@hosts, $params) }
    };

    summary 'Create a new host';
    params(
        requires('name', type => Str, desc => 'Host name'),
        requires('user_id', type => Int, desc => 'Host owner'),
        optional('state', type => Str, desc => 'Host state')
    );
    post sub {
        my $params = shift;
        { success => UseCase::Host::create(%$params) }
    };

    params(
        requires('id', type => Int, desc => 'Host ID')
    );
    route_param id => sub {
        summary 'Show a host';
        get sub {
            my $params = shift;
            { data => UseCase::Host::show($params->{id}) }
        };

        summary 'Edit a host';
        params(
            requires('state', type => Str, desc => 'Host state'),
        );
        put sub {
            my $params = shift;
            { data => UseCase::Host::edit($params->{id}, %$params) }
        };

        summary 'Edit a host';
        params(
            requires('state', type => Str, desc => 'Host state'),
        );
        patch sub {
            my $params = shift;
            { data => UseCase::Host::edit($params->{id}, %$params) }
        };


        summary 'Delete a host';
        del sub {
            my $params = shift;
            { success => UseCase::Host::remove($params->{id}) }
        }
    };
};

1;
