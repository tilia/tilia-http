tilia/http
=========

[![Build Status](https://travis-ci.org/tilia/tilia-http.svg?branch=master)](https://travis-ci.org/tilia/tilia-http)

**tilia/http is a port of [sabre/http](https://github.com/fruux/sabre-http)**

The sabre/http library provides a toolkit to make working with the HTTP protocol easier.

Most PHP scripts run within a HTTP request but accessing information about the
HTTP request is cumbersome at least.

There's bad practices, inconsistencies and confusion. This library is
effectively a wrapper around the following PHP constructs:

For Input:

* `$_GET`,
* `$_POST`,
* `$_SERVER`,
* `php://input` or `$HTTP_RAW_POST_DATA`.

For output:

* `php://output` or `echo`,
* `header()`.

What this library provides, is a `Request` object, and a `Response` object.

The objects are extendable and easily mockable.


Installation
------------

Simply add tilia-http to your Gemfile and bundle it up:

```ruby
  gem 'tilia-http', '~> 4.1'
```


Changes to sabre/http
---------------------

```php
  Sabre\HTTP\Message#setHeader($name, $value)
  Sabre\HTTP\Message#setHeader(array $headers)
```

are replaced by

```ruby
  Tilia::Http::Message#update_header(name, value)
  Tilia::Http::Message#update_headers(headers)
```


Contributing
------------

See [Contributing](CONTRIBUTING.md)


License
-------

tilia-http is licensed under the terms of the [three-clause BSD-license](LICENSE).
