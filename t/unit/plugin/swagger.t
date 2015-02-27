
use strict;
use warnings;

use FindBin '$Bin';
use Test::More;

use Raisin;
use Raisin::Plugin::Swagger;


sub _make_object {
    my $object = shift;

    my $caller = caller;
    my $app = Raisin->new(caller => $caller);

    my $module = Raisin::Plugin::Swagger->new($app);
    $module->build;

    $module;
}

# TODO: enable CORS

#subtest '_contact_object' => sub {
#    $obj::_contact_object(%);
#};

#subtest '_license_object' => sub {
#
#};

subtest '_info_object' => sub {
    my $m = _make_object;

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

        Raisin::swagger_setup(%{ $case->{settings} });
        is_deeply $m->_info_object, $case->{expected_object};
    }
};

#subtest '_parameters_object' => sub {
#
#};
#
#subtest '_operation_object' => sub {
#
#};
#
#subtest '_paths_object' => sub {
#
#};
#
#subtest '_tags_object' => sub {
#
#};
#
#subtest '_spec20' => sub {
#
#};

done_testing;
