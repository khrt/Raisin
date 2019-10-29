requires 'perl', '5.010000';

requires 'HTTP::Request::Common' => '0';
requires 'HTTP::Status' => '0';
requires 'Hash::Merge' => '0.300';
requires 'JSON::MaybeXS' => '1.004000';
requires 'Plack' => '1.0030';
requires 'Plack::Middleware::CrossOrigin' => '0.009';
requires 'Scalar::Util' => '1.38';
requires 'Type::Tiny' => '0.044';
requires 'YAML' => '0.90';
requires 'parent' => '0';

on test => sub {
    requires 'List::Util' => '1.29';
    requires 'Test::Exception' => '0';
    requires 'Test::Pod' => '0';
    requires 'Test::Simple' => '1.001014';
};

on develop => sub {
    requires 'Data::Printer' => '0.35';
    requires 'List::Util' => '1.29';
    requires 'Test::Exception' => '0';
    requires 'Test::Pod' => '0';
};
