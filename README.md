# NAME

Raisin - A REST-like API micro-framework for Perl.

# SYNOPSYS

    use Raisin::DSL;

    my %USERS = (
        1 => {
            name => 'Darth Wader',
            password => 'death',
            email => 'darth@deathstar.com',
        },
        2 => {
            name => 'Luke Skywalker',
            password => 'qwerty',
            email => 'l.skywalker@jedi.com',
        },
    );

    namespace '/user' => sub {
        get params => [
            #required/optional => [name, type, default, regex]
            optional => ['start', $Raisin::Types::Integer, 0],
            optional => ['count', $Raisin::Types::Integer, 10],
        ],
        sub {
            my $params = shift;
            my ($start, $count) = ($params->{start}, $params->{count});

            my @users
                = map { { id => $_, %{ $USERS{$_} } } }
                  sort { $a <=> $b } keys %USERS;

            $start = $start > scalar @users ? scalar @users : $start;
            $count = $count > scalar @users ? scalar @users : $count;

            my @slice = @users[$start .. $count];
            { data => \@slice }
        };

        post params => [
            required => ['name', $Raisin::Types::String],
            required => ['password', $Raisin::Types::String],
            optional => ['email', $Raisin::Types::String, undef, qr/.+\@.+/],
        ],
        sub {
            my $params = shift;

            my $id = max(keys %USERS) + 1;
            $USERS{$id} = $params;

            { success => 1 }
        };

        route_param 'id' => $Raisin::Types::Integer,
        sub {
            get sub {
                my $params = shift;
                %USERS{ $params->{id} };
            };
        };
    };

    run;

# DESCRIPTION

Raisin is a REST-like API micro-framework for Perl.
It's designed to run on Plack, providing a simple DSL
to easily develop RESTful APIs.

It's a clone of [Grape](https://github.com/intridea/grape).

# KEYWORDS

## namespace

    namespace user => sub { ... };

## route\_param

    route_param id => $Raisin::Types::Integer, sub { ... };

## delete, get, post, put

These are shortcuts to `route` restricted to the corresponding HTTP method.

    get sub { 'GET' };

    get params => [
        required => ['id', $Raisin::Types::Integer],
        optional => ['key', $Raisin::Types::String],
    ],
    sub { 'GET' };

## req

An alias for `$self->req`, this provides quick access to the
[Raisin::Request](https://metacpan.org/pod/Raisin::Request) object for the current route.

## res

An alias for `$self->res`, this provides quick access to the
[Raisin::Response](https://metacpan.org/pod/Raisin::Response) object for the current route.

## params

An alias for `$self->params` that gets the GET and POST parameters.
When used with no arguments, it will return an array with the names of all http
parameters. Otherwise, it will return the value of the requested http parameter.

## session

An alias for `$self->session` that returns (optional) psgix.session hash.
When it exists, you can retrieve and store per-session data from and to this hash.

## plugin

Loads a Raisin module. The module options may be specified after the module name.
Compatible with [Kelp](https://metacpan.org/pod/Kelp) modules.

    plugin 'Logger' => outputs => [['Screen', min_level => 'debug']];

## api\_format

Load a `Raisin::Plugin::Format` plugin. Already exists [Raisin::Plugin::Format::JSON](https://metacpan.org/pod/Raisin::Plugin::Format::JSON)
and [Raisin::Plugin::Format::YAML](https://metacpan.org/pod/Raisin::Plugin::Format::YAML).

    api_format 'JSON';

## mount

Mount multiple API implementations inside another one.  These don't have to be
different versions, but may be components of the same API.

    mount 'RApp::User';
    mount 'RApp::Host';

## run, new

Creates and returns a PSGI ready subroutine, and makes the app ready for `Plack`.

# ROUTING

about routing

# PARAMETERS

    get params => [
        optional => ['start', $Raisin::Types::Integer, 0],
        optional => ['count', $Raisin::Types::Integer, 10],
        required => ['email', $Raisin::Types::String, undef, qr/[^@]@[^.].\w+/],
    ],

## Declared params

required/optional => \[name, type, default, regex\]

## Types

See [Raisin::Types](https://metacpan.org/pod/Raisin::Types)

# HOOKS

`before`, `before_validation`, `after_validation`, `after`

# ADDING MIDDLEWARE

You can easily add middleware to your application using `middleware` keyword.

# PLUGINS

See [Raisin::Plugin](https://metacpan.org/pod/Raisin::Plugin)

# DEPLOYING

Plack::Builder ...

# GitHub

https://github.com/khrt/Raisin

# AUTHOR

Artur Khabibullin - khrt <at> ya.ru

# ACKNOWLEDGEMENTS

This module's interface was inspired by [Kelp](https://metacpan.org/pod/Kelp), which was inspired [Dancer](https://metacpan.org/pod/Dancer),
which in its turn was inspired by Sinatra, so Viva La Open Source!

# LICENSE

This module and all the modules in this package are governed by the same license
as Perl itself.
