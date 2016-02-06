#!/usr/bin/env ruby
require 'json'
# This simple example shows the capability of Request and Response objects to
# serialize themselves as strings.
#
# This is mainly useful for debugging purposes.

# Expected to be called "bundle exec examples/stringify.rb"
require 'tilia/http'

request = Tilia::Http::Request.new('POST', '/foo')
request.update_headers(
  'Host'         => 'example.org',
  'Content-Type' => 'application/json'
)

request.body = JSON.generate('foo' => 'bar')

puts request.to_s
puts
puts

response = Tilia::Http::Response.new(424)
response.update_headers(
  'Content-Type' => 'text/plain',
  'Connection'   => 'close'
)

response.body = 'ABORT! ABORT!'

puts response.to_s

puts
