#!/usr/bin/env ruby
# The url we're proxying to.
remote_url = 'http://example.org/'

# The url we're proxying from. Please note that this must be a relative url,
# and basically acts as the base url.
#
# If your remote_url doesn't end with a slash, this one probably shouldn't
# either.
my_base_url = ''
# my_base_url = '/~evert/sabre/http/examples/reverseproxy.php/'

# Expected to be called "bundle exec examples/reverseproxy.rb"
require './lib/tilia_http'
require 'rack'

app = proc do |env|
  sapi = Tilia::Http::Sapi.new(env)
  request = sapi.request
  request.base_url = my_base_url

  sub_request = request.dup

  # Removing the Host header.
  sub_request.remove_header('Host')

  # Rewriting the url.
  sub_request.url = remote_url + request.path

  client = Tilia::Http::Client.new

  # Sends the HTTP request to the server
  response = client.send(sub_request)

  # Sends the response back to the client that connected to the proxy.
  sapi.send_response(response)
end

Rack::Handler::WEBrick.run app
