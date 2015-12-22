require 'base64'
module Tilia
  module Http
    module Auth
      # HTTP Basic authentication utility.
      #
      # This class helps you setup basic auth. The process is fairly simple:
      #
      # 1. Instantiate the class.
      # 2. Call getCredentials (this will return null or a user/pass pair)
      # 3. If you didn't get valid credentials, call 'requireLogin'
      class Basic < Tilia::Http::Auth::AbstractAuth
        # This method returns a numeric array with a username and password as the
        # only elements.
        #
        # If no credentials were found, this method returns null.
        #
        # @return null|array
        def credentials
          auth = @request.header('Authorization')

          return nil unless auth
          return nil unless auth[0..5].downcase == 'basic '

          credentials = Base64.decode64(auth[6..-1]).split(':', 2)

          return nil unless credentials.size == 2

          credentials
        end

        # This method sends the needed HTTP header and statuscode (401) to force
        # the user to login.
        #
        # @return void
        def require_login
          @response.add_header('WWW-Authenticate', "Basic realm=\"#{@realm}\"")
          @response.status = 401
        end
      end
    end
  end
end
