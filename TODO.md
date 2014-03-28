Params as a main word
=====================
Start route definition with the `params` keyword like in Grape:

    params [
      requires => ['name', $Raisin::Types::String],
    ],
    get '/suburl' => sub {
        'ok'
    };

---

    params [
      requires => ['name', $Raisin::Types::String],
    ],
    post sub {
        'ok'
    };


Token auth
==========
    * Plack middleware;
    * Raisin plugin;

See Plack::Middleware::Auth::AccessToken.


Output format
=============
    * based on accept content type header;
    * based on path extension;
Path extension should have more priority rather accept header.


DONE: Refactor Types
==============
Types should be a class with a `Raisin::Types::Base` parent.
Example of an Integer type:

    package Raisin::Types::Integer;
    use base 'Raisin::Types::Base';

    has regex => qr/^\d+$/;

    has check => sub {
      length($v) <= 10 ? 1 : 0
    };

    has in => sub {
      my $v = shift;
      $$v = sprintf 'INT:%d', $$v;
    };


Make changes in `Raisin::Routes::Endpoint` to use a regex from types.
Implement simple attributes class.

Base class `Raisin::Types::Base` should be something like this:

    package Raisin::Types::Base;

    use strict;
    use warnings;

    sub import {
      # import strict, warnings, has;
    }

    sub new {
      my ($class, $value) = @_;
      my $self = bless {}, $class;

      ($self->{type}) = $class =~ /::(.+)$/;

      if ($self->regex) {
        ($self->regex =~ $value) or return;
      }

      $self->check($value) or return;
      $self->in(\$value);
      1;
    }

    has regex => undef;
    has check => sub { 1 };
    has in => sub { 1 };

    1;

Do not forget to update DOCS!!!


DONE: Path params
===========
_get/post/put/delete/..._ etc. should take path params;
Don't forget to update DOCS!!!

    get '/suburl' => sub {
      'ok';
    };

