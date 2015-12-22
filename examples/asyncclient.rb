#!/usr/bin/env ruby
# This example demonstrates the ability for clients to work asynchronously.
#
# By default up to 10 requests will be executed in paralel. HTTP connections
# are re-used and DNS is cached, all thanks to the power of curl.
#
# @copyright Copyright (C) 2009-2015 fruux GmbH (https://fruux.com/).
# @author Evert Pot (http://evertpot.com/)
# @license http://sabre.io/license/ Modified BSD License

# Expected to be called "bundle exec examples/asyncclient.rb"
require './lib/tilia/http'

# This is the request we're repeating a 1000 times.
request = Tilia::Http::Request.new('GET', 'http://localhost/')
client = Tilia::Http::Client.new

1000.times do |i|
  puts "#{i}\tsending"

  # This is the 'success' callback
  success = lambda do |response|
    puts "#{i}\t#{response.status}"
  end

  # This is the 'error' callback. It is called for general connection
  # problems (such as not being able to connect to a host, dns errors,
  # etc.) and also cases where a response was returned, but it had a
  # status code of 400 or higher.
  exception = lambda do |error|
    if error['status'] == Tilia::Http::Client::STATUS_CURLERROR
      # Curl errors
      puts "#{i}\tcurl error: #{error['curl_errmsg']}"
    else
      # HTTP errors
      puts "#{i}\t#{error['response'].status}"
    end
  end

  client.send_async(request, success, exception)
end

# After everything is done, we call 'wait'. This causes the client to wait for
# all outstanding http requests to complete.
client.wait
