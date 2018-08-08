requires 'perl', '5.010000';

#requires 'Carp' => '1.20';
#requires 'Data::Dumper' => '2.131';
#requires 'File::Basename' => '0';
#requires 'File::Path' => '0';
#requires 'Getopt::Long' => '0';
#requires 'POSIX' => '0';
#requires 'Pod::Usage' => '0';
#requires 'Term::ANSIColor' => '0';
#requires 'Time::HiRes' => '1.9724';

#requires 'Log::Dispatch' => '2.39';
#requires 'Hash::MultiValue';
requires 'JSON' => '2.90';
requires 'Plack' => '1.0030';
requires 'Plack::Middleware::CrossOrigin' => '0.009';
requires 'Scalar::Util' => '1.38';
requires 'Type::Tiny' => '0.044';
requires 'YAML' => '0.90';
requires 'HTTP::Status' => '0';

on test => sub {
    requires 'Test::More' => '0.88';
    requires 'List::Util' => '1.29';
};

on develop => sub {
    requires 'Data::Printer' => '0.35';
    requires 'List::Util' => '1.29';
};
