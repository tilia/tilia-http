#!/usr/bin/env ruby
# This example shows how to make a HTTP request with the Request and Response
# objects.
#
# @copyright Copyright (C) 2009-2015 fruux GmbH (https://fruux.com/).
# @author Evert Pot (http://evertpot.com/)
# @license http://sabre.io/license/ Modified BSD License

# Expected to be called "bundle exec examples/client.rb"
require './lib/tilia_http'

# Constructing the request.
request = Tilia::Http::Request.new('GET', 'http://www.jakobsack.de/')

client = Tilia::Http::Client.new
# client.add_curl_setting(proxy: 'localhost:8888')
response = client.send(request)

puts 'Response:'
puts response.to_s
