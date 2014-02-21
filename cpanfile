requires 'perl', '5.008005';

requires 'Carp' => '0';
requires 'JSON' => '0';
requires 'Plack' => '1.0030';
requires 'YAML' => '0';
requires 'Plack::Middleware::CrossOrigin' => '0.009';

on test => sub {
    requires 'Test::More', '0.88';
};
