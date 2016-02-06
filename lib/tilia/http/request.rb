require 'cgi'
module Tilia
  module Http
    # The Request class represents a single HTTP request.
    #
    # You can either simply construct the object from scratch, or if you need
    # access to the current HTTP request, use Sapi::getRequest.
    class Request
      include Tilia::Http::Message
      include Tilia::Http::RequestInterface

      # Creates the request object
      #
      # @param [String] method
      # @param [String] url
      # @param [Hash] headers
      # @param [String, IO] body
      def initialize(method = nil, url = nil, headers = nil, body = nil)
        super()

        @base_url = '/' # RUBY
        @post_data = {}
        @raw_server_data = {}

        fail ArgumentError, 'The first argument for this constructor should be a string or null, not an array. Did you upgrade from sabre/http 1.0 to 2.0?' if method.is_a?(Array)

        @method = method if method
        @url = url if url
        update_headers(headers) if headers
        @body = body if body
      end

      # (see RequestInterface#method)
      attr_reader :method

      # (see RequestInterface#method=)
      attr_writer :method

      # (see RequestInterface#url)
      attr_reader :url

      # (see RequestInterface#url=)
      attr_writer :url

      # (see RequestInterface#query_parameters)
      def query_parameters
        url = self.url

        if !(index = url.index('?'))
          {}
        else
          query_params = CGI.parse(url[index + 1..-1])
          query_params.keys.each do |key|
            query_params[key] = query_params[key][0] if query_params[key].size == 1
            query_params[key] = nil if query_params[key].size == 0
          end
          query_params
        end
      end

      # (see RequestInterface#absolute_url=)
      attr_writer :absolute_url

      # (see RequestInterface#absolute_url)
      attr_reader :absolute_url

      # (see RequestInterface#base_url=)
      attr_writer :base_url

      # (see RequestInterface#base_url)
      attr_reader :base_url

      # (see RequestInterface#path)
      def path
        # Removing duplicated slashes.
        uri = (url || '').gsub('//', '/')

        uri = Tilia::Uri.normalize(uri)
        base_uri = Tilia::Uri.normalize(base_url)

        if uri.index(base_uri) == 0
          # We're not interested in the query part (everything after the ?).
          uri = uri.split('?').first
          return Tilia::Http::UrlUtil.decode_path(uri[base_uri.size..-1]).gsub(%r{^/+|/+$}, '')
        elsif uri + '/' == base_uri
          # A special case, if the baseUri was accessed without a trailing
          # slash, we'll accept it as well.
          return ''
        end

        fail "Requested uri (#{url}) is out of base uri (#{base_url})"
      end

      # (see RequestInterface#post_data=)
      attr_writer :post_data

      # (see RequestInterface#post_data)
      attr_reader :post_data

      # (see RequestInterface#raw_server_value)
      def raw_server_value(value_name)
        @raw_server_data[value_name]
      end

      # (see RequestInterface#raw_server_data=)
      def raw_server_data=(data)
        @raw_server_data = data.dup
      end

      # Serializes the request object as a string.
      #
      # This is useful for debugging purposes.
      #
      # @return [String]
      def to_s
        out = "#{method} #{url} HTTP/#{http_version}\r\n"

        headers.each do |key, value|
          value.each do |v|
            if key == 'Authorization'
              v = v.split(' ').first
              v << ' REDACTED'
            end
            out << "#{key}: #{v}\r\n"
          end
        end

        out << "\r\n"
        out << body_as_string

        out
      end
    end
  end
end
