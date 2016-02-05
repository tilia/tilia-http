require 'digest'
module Tilia
  module Http
    module Auth
      # HTTP Digest Authentication handler
      #
      # Use this class for easy http digest authentication.
      # Instructions:
      #
      #  1. Create the object
      #  2. Call the set_realm method with the realm you plan to use
      #  3. Call the init method function.
      #  4. Call the user_name function. This function may return null if no
      #     authentication information was supplied. Based on the username you
      #     should check your internal database for either the associated password,
      #     or the so-called A1 hash of the digest.
      #  5. Call either validate_password or validate_a1. This will return true
      #     or false.
      #  6. To make sure an authentication prompt is displayed, call the
      #     require_login method.
      class Digest < Tilia::Http::Auth::AbstractAuth
        # These constants are used in qop
        QOP_AUTH = 1
        QOP_AUTHINT = 2

        # Initializes the object
        def initialize(realm = 'TiliaTooth', request, response)
          @qop = QOP_AUTH

          @nonce = ::Digest::SHA1.hexdigest((Time.now.to_f + rand).to_s)[0..14]
          @opaque = ::Digest::MD5.hexdigest(realm)
          super(realm, request, response)
        end

        # Gathers all information from the headers
        #
        # This method needs to be called prior to anything else.
        #
        # @return [void]
        def init
          digest = self.digest || ''
          @digest_parts = parse_digest(digest)
        end

        # Sets the quality of protection value.
        #
        # Possible values are:
        #   Sabre\HTTP\DigestAuth::QOP_AUTH
        #   Sabre\HTTP\DigestAuth::QOP_AUTHINT
        #
        # Multiple values can be specified using logical OR.
        #
        # QOP_AUTHINT ensures integrity of the request body, but this is not
        # supported by most HTTP clients. QOP_AUTHINT also requires the entire
        # request body to be md5'ed, which can put strains on CPU and memory.
        #
        # @param int qop
        # @return [void]
        attr_writer :qop

        # Validates the user.
        #
        # The A1 parameter should be md5(username . ':' . realm . ':' . password)
        #
        # @param [String] a1
        # @return bool
        def validate_a1(a1)
          @a1 = a1
          validate
        end

        # Validates authentication through a password. The actual password must be provided here.
        # It is strongly recommended not store the password in plain-text and use validateA1 instead.
        #
        # @param [String] password
        # @return bool
        def validate_password(password)
          return false unless @digest_parts.any? # RUBY

          @a1 = ::Digest::MD5.hexdigest(@digest_parts['username'] + ':' + @realm + ':' + password)
          validate
        end

        # Returns the username for the request
        #
        # @return [String]
        def username
          @digest_parts['username']
        end

        protected

        # Validates the digest challenge
        #
        # @return bool
        def validate
          return false unless @digest_parts.any? # RUBY

          a2 = @request.method + ':' + @digest_parts['uri']

          if @digest_parts['qop'] == 'auth-int'
            # Making sure we support this qop value
            return false unless @qop & QOP_AUTHINT

            # We need to add an md5 of the entire request body to the A2 part of the hash
            body = @request.body_as_string
            @request.body = body

            a2 << ':' + ::Digest::MD5.hexdigest(body)
          else
            # We need to make sure we support this qop value
            return false unless @qop & QOP_AUTH
          end

          a2 = ::Digest::MD5.hexdigest(a2)
          valid_response = ::Digest::MD5.hexdigest("#{@a1}:#{@digest_parts['nonce']}:#{@digest_parts['nc']}:#{@digest_parts['cnonce']}:#{@digest_parts['qop']}:#{a2}")

          @digest_parts['response'] == valid_response
        end

        public

        # Returns an HTTP 401 header, forcing login
        #
        # This should be called when username and password are incorrect, or not supplied at all
        #
        # @return [void]
        def require_login
          qop = ''
          case @qop
          when QOP_AUTH
            qop = 'auth'
          when QOP_AUTHINT
            qop = 'auth-int'
          when QOP_AUTH | QOP_AUTHINT
            qop = 'auth,auth-int'
          end

          @response.add_header('WWW-Authenticate', "Digest realm=\"#{@realm}\",qop=\"#{qop}\",nonce=\"#{@nonce}\",opaque=\"#{@opaque}\"")
          @response.status = 401
        end

        # This method returns the full digest string.
        #
        # It should be compatibile with mod_php format and other webservers.
        #
        # If the header could not be found, null will be returned
        #
        # @return mixed
        def digest
          @request.header('Authorization')
        end

        protected

        # Parses the different pieces of the digest string into an array.
        #
        # This method returns false if an incomplete digest was supplied
        #
        # @param [String] digest
        # @return mixed
        def parse_digest(digest)
          # protect against missing data
          needed_parts = { 'nonce' => 1, 'nc' => 1, 'cnonce' => 1, 'qop' => 1, 'username' => 1, 'uri' => 1, 'response' => 1 }
          data = {}

          digest.scan(/(\w+)=(?:(?:")([^"]+)"|([^\s,$]+))/) do |m1, m2, m3|
            data[m1] = m2 ? m2 : m3
            needed_parts.delete m1
          end

          needed_parts.any? ? {} : data
        end
      end
    end
  end
end
