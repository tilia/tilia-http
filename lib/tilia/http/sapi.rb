require 'stringio'
require 'base64'
module Tilia
  module Http
    # PHP SAPI
    #
    # This object is responsible for:
    # 1. Constructing a Request object based on the current HTTP request sent to
    #    the PHP process.
    # 2. Sending the Response object back to the client.
    #
    # It could be said that this class provides a mapping between the Request and
    # Response objects, and php's:
    #
    # * $_SERVER
    # * $_POST
    # * $_FILES
    # * php://input
    # * echo
    # * header
    # * php://output
    #
    # You can choose to either call all these methods statically, but you can also
    # instantiate this as an object to allow for polymorhpism.
    class Sapi
      # This static method will create a new Request object, based on the
      # current PHP request.
      #
      # @return Request
      def self.request
        fail NotImplementedError, 'This object method now is an instance method'
      end

      # Sends the HTTP response back to a HTTP client.
      #
      # This calls php's header function and streams the body to php://output.
      #
      # @param ResponseInterface response
      # @return [void]
      def self.send_response(response)
        # RUBY: Rack does not support HTTP Version (?)
        # header("HTTP/#{response.http_version} #{response.status} #{response.status_text}")

        status = response.status
        headers = {}
        response.headers.each do |key, value|
          headers[key] = value.join("\n")
        end

        body = response.body_as_stream
        content_length = response.header('Content-Length')
        if content_length
          output = StringIO.new
          output.write body.read(content_length.to_i)
          output.rewind
          body = output
        end

        [status, headers, body]
      end

      # This static method will create a new Request object, based on a PHP
      # $_SERVER array.
      #
      # @param array server_array
      # @return Request
      def self.create_from_server_array(server_array)
        headers = {}
        method = nil
        url = nil
        http_version = '1.1'

        protocol = 'http'
        host_name = 'localhost'

        server_array.each do |key, value|
          case key
          when 'SERVER_PROTOCOL'
            http_version = '1.0' if value == 'HTTP/1.0'
          when 'REQUEST_METHOD'
            method = value
          when 'REQUEST_URI'
            url = value

          # These sometimes should up without a HTTP_ prefix
          when 'CONTENT_TYPE'
            headers['Content-Type'] = value
          when 'CONTENT_LENGTH'
            headers['Content-Length'] = value

          # mod_php on apache will put credentials in these variables.
          # (fast)cgi does not usually do this, however.
          when 'PHP_AUTH_USER'
            if server_array.key? 'PHP_AUTH_PW'
              headers['Authorization'] = "Basic #{Base64.strict_encode64 "#{value}:#{server_array['PHP_AUTH_PW']}"}"
            end
          when 'PHP_AUTH_DIGEST'
            headers['Authorization'] = "Digest #{value}"

          # Apache may prefix the HTTP_AUTHORIZATION header with
          # REDIRECT_, if mod_rewrite was used.
          when 'REDIRECT_HTTP_AUTHORIZATION'
            headers['Authorization'] = value

          when 'HTTP_HOST'
            host_name = value
            headers['Host'] = value

          when 'HTTPS'
            protocol = 'https' if value && value != 'off'

          # RUBY
          when 'rack.url_scheme'
            protocol = value

          else
            if key.index('HTTP_') == 0
              # It's a HTTP header

              # Normalizing it to be prettier
              header = key[5..-1].downcase

              # Transforming dashes into spaces, and uppercasing
              # every first letter.
              # Turning spaces into dashes.
              header = header.split(/_/).map(&:capitalize).join('-')

              headers[header] = value
            end
          end
        end

        r = Tilia::Http::Request.new(method, url, headers)
        r.http_version = http_version
        r.raw_server_data = server_array
        r.absolute_url = "#{protocol}://#{host_name}#{url}"
        r
      end

      # TODO: document
      def initialize(env)
        @env = env
        @rack_request = Rack::Request.new(env)
      end

      # TODO: document
      def request
        r = create_from_server_array(@env)
        r.body = StringIO.new
        r.post_data = @rack_request.POST
        r
      end

      # TODO: document
      def send_response(response)
        self.class.send_response(response)
      end

      # TODO: document
      def create_from_server_array(server_array)
        self.class.create_from_server_array(server_array)
      end
    end
  end
end
