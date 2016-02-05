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

  digest_auth = Tilia::Http::Auth::Digest.new('Locked down area', request, response)
  digest_auth.init

  if !(user_name = digest_auth.username)
    # No username or password given
    digest_auth.require_login
  elsif !user_list.key?(user_name) || !digest_auth.validate_password(userlist[user_name])
    # Username or password are incorrect
    digest_auth.require_login
  else
    # Success !
    response.body = 'You are logged in!'
  end

  # Sending the response
  sapi.send_response(response)
end

Rack::Handler::WEBrick.run app
