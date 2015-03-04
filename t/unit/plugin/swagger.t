
use strict;
use warnings;

use Test::More;

use Raisin;
use Raisin::Plugin::Swagger;

sub _make_object {
    my (%args) = @_;

    my $caller = caller;
    my $app = Raisin->new(caller => $caller);

    my $module = Raisin::Plugin::Swagger->new($app);
    $module->build(%args);

    $module;
}

my $m = _make_object(enable => 'CORS');

is $m->{swagger_version}, '2.0', 'Swagger 2.0 docs';
ok defined $m->app->{middleware}{CrossOrigin}, 'CORS OK';

subtest '_info_object' => sub {
    # + _contact_object, _license_object
    my @CASES = (
        {
            settings => {},
            expected_object => {
                title => 'API',
                version => '0.0.1',
            },
        },
        {
            settings => {
                title => 'Test API',
                version => 'Test v0.0.1',
                description => 'Test API description',
                terms_of_service => '?',
                contact => {
                    email => 'rtkh@cpan.org',
                    name => 'Artur Khabibullin',
                    url => 'https://metacpan.org/author/RTKH',
                },
                license => {
                    name => 'Perl license',
                    url => 'http://dev.perl.org/licenses/',
                },
            },
            expected_object => {
                title => 'Test API',
                version => 'Test v0.0.1',
                description => 'Test API description',
                termsOfService => '?',
                contact => {
                    email => 'rtkh@cpan.org',
                    name => 'Artur Khabibullin',
                    url => 'https://metacpan.org/author/RTKH',
                },
                license => {
                    name => 'Perl license',
                    url => 'http://dev.perl.org/licenses/',
                },
            },
        }
    );

    for my $case (@CASES) {
        $m->app->api_version($case->{settings}{version})
            if $case->{settings}{version};

        swagger_setup(%{ $case->{settings} });
        is_deeply $m->_info_object, $case->{expected_object};
    }
};

subtest '_parameters_object' => sub {
    plan skip_all => 'TODO';
};

subtest '_operation_object' => sub {
    plan skip_all => 'TODO';
};

subtest '_paths_object' => sub {
    plan skip_all => 'TODO';
};

subtest '_tags_object' => sub {
    plan skip_all => 'TODO';
};

subtest '_spec20' => sub {
    plan skip_all => 'TODO';
};

done_testing;
