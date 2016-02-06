#!/usr/bin/env ruby
# This example shows how to make a HTTP request with the Request and Response
# objects.

# Expected to be called "bundle exec examples/client.rb"
require 'tilia/http'

# Constructing the request.
request = Tilia::Http::Request.new('GET', 'http://www.jakobsack.de/')

client = Tilia::Http::Client.new
# client.add_curl_setting(proxy: 'localhost:8888')
response = client.send_request(request)

puts 'Response:'
puts response.to_s
