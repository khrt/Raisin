Path params
===========
_get/post/put/delete/..._ etc. should take path params;
Don't forget to update DOCS!!!


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

