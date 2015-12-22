#!/usr/bin/env ruby
# This example does not work because of rack ...
# This example shows how to do Basic authentication.
# *
# @copyright Copyright (C) 2009-2015 fruux GmbH (https://fruux.com/).
# @author Evert Pot (http://evertpot.com/)
# @license http://sabre.io/license/ Modified BSD License

# Expected to be called "bundle exec examples/basicauth.rb"
require './lib/tilia_http'
require 'rack'

app = proc do |env|
  user_list = {
    'user1' => 'password',
    'user2' => 'password'
  }

  sapi = Tilia::Http::Sapi.new(env)
  request = sapi.request
  response = Tilia::Http::Response.new

  basic_auth = Tilia::Http::Auth::Basic.new('Locked down area', request, response)
  if !(user_pass = basic_auth.credentials)
    # No username or password given
    basic_auth.require_login
  elsif !user_list.key?(user_pass[0]) || user_list[user_pass[0]] != user_pass[1]
    # Username or password are incorrect
    basic_auth.require_login
  else
    # Success !
    response.body = 'You are logged in!'
  end

  # Sending the response
  sapi.send_response(response)
end

Rack::Handler::WEBrick.run app
