require 'digest'
require 'base64'
require 'openssl'
module Tilia
  module Http
    module Auth
      # HTTP AWS Authentication handler
      #
      # Use this class to leverage amazon's AWS authentication header
      class Aws < Tilia::Http::Auth::AbstractAuth
        # An error code, if any
        #
        # This value will be filled with one of the ERR_* constants
        #
        # @return int
        attr_accessor :error_code

        ERR_NOAWSHEADER = 1
        ERR_MD5CHECKSUMWRONG = 2
        ERR_INVALIDDATEFORMAT = 3
        ERR_REQUESTTIMESKEWED = 4
        ERR_INVALIDSIGNATURE = 5

        # Gathers all information from the headers
        #
        # This method needs to be called prior to anything else.
        #
        # @return bool
        def init
          auth_header = @request.header('Authorization') || ''
          auth_header = auth_header.split(' ')

          if auth_header[0] != 'AWS' || auth_header.size < 2
            @error_code = ERR_NOAWSHEADER
            return false
          end

          (@access_key, @signature) = auth_header[1].split(':')

          true
        end

        # Returns the username for the request
        #
        # @return [String]
        attr_reader :access_key

        # Validates the signature based on the secretKey
        #
        # @param [String] secret_key
        # @return bool
        def validate(secret_key)
          content_md5 = @request.header('Content-MD5')

          if content_md5.present?
            # We need to validate the integrity of the request
            body = @request.body
            @request.body = body

            if content_md5 != Base64.strict_encode64(::Digest::MD5.digest(body.to_s))
              # content-md5 header did not match md5 signature of body
              @error_code = ERR_MD5CHECKSUMWRONG
              return false
            end
          end

          request_date = @request.header('x-amz-date')
          request_date = @request.header('Date') unless request_date

          return false unless validate_rfc2616_date(request_date)

          amz_headers = self.amz_headers

          signature = Base64.strict_encode64(
            hmacsha1(
              secret_key,
              @request.method + "\n" +
              content_md5 + "\n" +
              @request.header('Content-type').to_s + "\n" +
              request_date + "\n" +
              amz_headers +
              @request.url
            )
          )

          unless @signature == signature
            @error_code = ERR_INVALIDSIGNATURE
            return false
          end
          true
        end

        # Returns an HTTP 401 header, forcing login
        #
        # This should be called when username and password are incorrect, or not supplied at all
        #
        # @return [void]
        def require_login
          @response.add_header('WWW-Authenticate', 'AWS')
          @response.status = 401
        end

        protected

        # Makes sure the supplied value is a valid RFC2616 date.
        #
        # If we would just use strtotime to get a valid timestamp, we have no way of checking if a
        # user just supplied the word 'now' for the date header.
        #
        # This function also makes sure the Date header is within 15 minutes of the operating
        # system date, to prevent replay attacks.
        #
        # @param [String] date_header
        # @return bool
        def validate_rfc2616_date(date_header)
          date = Tilia::Http::Util.parse_http_date(date_header)

          # Unknown format
          unless date
            @error_code = ERR_INVALIDDATEFORMAT
            return false
          end

          min = Time.zone.now - 15.minutes
          max = Time.zone.now + 15.minutes

          # We allow 15 minutes around the current date/time
          if date > max || date < min
            @error_code = ERR_REQUESTTIMESKEWED
            return false
          end

          date
        end

        # Returns a list of AMZ headers
        #
        # @return [String]
        def amz_headers
          amz_headers = {}
          headers = @request.headers

          headers.each do |header_name, header_value|
            if header_name.downcase.index('x-amz-') == 0
              amz_headers[header_name.downcase] = header_value[0].gsub(/\r?\n/, ' ') + "\n"
            end
          end

          header_str = ''
          amz_headers.keys.sort.each do |h|
            header_str << "#{h}:#{amz_headers[h]}"
          end

          header_str
        end

        private

        # Generates an HMAC-SHA1 signature
        #
        # @param [String] key
        # @param [String] message
        # @return [String]
        def hmacsha1(key, message)
          # Built in in Ruby
          OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), key, message)
        end

        # Initialize instance variables
        def initialize(realm = 'TiliaTooth', request, response)
          super
          @error_code = 0
        end
      end
    end
  end
end
