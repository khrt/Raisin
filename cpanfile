requires 'perl', '5.010001';

# Built-in
requires 'Carp' => '1.20';
requires 'Data::Dumper' => '2.131';
requires 'File::Basename' => '0';
requires 'File::Path' => '0';
requires 'Getopt::Long' => '0';
requires 'List::Util' => '1.34';
requires 'POSIX' => '0';
requires 'Time::HiRes' => '1.9724';

# External
requires 'File::Slurp' => '0';
requires 'JSON' => '2.90';
requires 'Log::Dispatch' => '2.39';
requires 'Plack' => '1.0030';
requires 'Plack::Middleware::CrossOrigin' => '0.009';
requires 'YAML' => '0.90';

on test => sub {
    requires 'Test::More' => '0.88';
};

on develop => sub {
    requires 'Data::Printer' => '0.35';
};
