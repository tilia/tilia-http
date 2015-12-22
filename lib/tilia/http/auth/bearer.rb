module Tilia
  module Http
    module Auth
      # HTTP Bearer authentication utility.
      #
      # This class helps you setup bearer auth. The process is fairly simple:
      #
      # 1. Instantiate the class.
      # 2. Call getToken (this will return null or a token as string)
      # 3. If you didn't get a valid token, call 'requireLogin'
      class Bearer < Tilia::Http::Auth::AbstractAuth
        # This method returns a string with an access token.
        #
        # If no token was found, this method returns null.
        #
        # @return null|string
        def token
          auth = @request.header('Authorization')

          return nil unless auth
          return nil unless auth[0..6].downcase == 'bearer '

          auth[7..-1]
        end

        # This method sends the needed HTTP header and statuscode (401) to force
        # authentication.
        #
        # @return [void]
        def require_login
          @response.add_header('WWW-Authenticate', "Bearer realm=\"#{@realm}\"")
          @response.status = 401
        end
      end
    end
  end
end
