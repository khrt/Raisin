requires 'perl', '5.008005';

requires 'Carp' => '0';
requires 'JSON' => '0';
requires 'Log::Dispatch' => '2.39';
requires 'Plack' => '1.0030';
requires 'Plack::Middleware::CrossOrigin' => '0.009';
requires 'YAML' => '0';

on test => sub {
    requires 'Test::More' => '0.88';
};

on develop => sub {
    requires 'Data::Printer' => '0.35';
};
