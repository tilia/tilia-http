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

      protected

      # HTTP Method
      #
      # @return [String]
      attr_accessor :method

      # Request Url
      #
      # @return [String]
      attr_accessor :url

      public

      # Creates the request object
      #
      # @param [String] method
      # @param [String] url
      # @param array headers
      # @param resource body
      def initialize(method = nil, url = nil, headers = nil, body = nil)
        initialize_message
        @base_url = '/' # RUBY
        @post_data = {}
        @raw_server_data = {}

        fail ArgumentError, 'The first argument for this constructor should be a string or null, not an array. Did you upgrade from sabre/http 1.0 to 2.0?' if method.is_a?(Array)

        self.method = method if method
        self.url = url if url
        update_headers(headers) if headers
        self.body = body if body
      end

      # Returns the current HTTP method
      #
      # @return [String]
      attr_reader :method

      # Sets the HTTP method
      #
      # @param [String] method
      # @return [void]
      attr_writer :method

      # Returns the request url.
      #
      # @return [String]
      attr_reader :url

      # Sets the request url.
      #
      # @param [String] url
      # @return [void]
      attr_writer :url

      # Returns the list of query parameters.
      #
      # This is equivalent to PHP's $_GET superglobal.
      #
      # @return array
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

      # Sets the absolute url.
      #
      # @param [String] url
      # @return [void]
      attr_writer :absolute_url

      # Returns the absolute url.
      #
      # @return [String]
      attr_reader :absolute_url

      protected

      # Base url
      #
      # @return [String]
      attr_accessor :base_url

      public

      # Sets a base url.
      #
      # This url is used for relative path calculations.
      #
      # @param [String] url
      # @return [void]
      attr_writer :base_url

      # Returns the current base url.
      #
      # @return [String]
      attr_reader :base_url

      # Returns the relative path.
      #
      # This is being calculated using the base url. This path will not start
      # with a slash, so it will always return something like
      # 'example/path.html'.
      #
      # If the full path is equal to the base url, this method will return an
      # empty string.
      #
      # This method will also urldecode the path, and if the url was incoded as
      # ISO-8859-1, it will convert it to UTF-8.
      #
      # If the path is outside of the base url, a LogicException will be thrown.
      #
      # @return [String]
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

      protected

      # Equivalent of PHP's $_POST.
      #
      # @return array
      attr_accessor :post_data

      public

      # Sets the post data.
      #
      # This is equivalent to PHP's $_POST superglobal.
      #
      # This would not have been needed, if POST data was accessible as
      # php://input, but unfortunately we need to special case it.
      #
      # @param array post_data
      # @return [void]
      attr_writer :post_data

      # Returns the POST data.
      #
      # This is equivalent to PHP's $_POST superglobal.
      #
      # @return array
      attr_reader :post_data

      protected

      # An array containing the raw _SERVER array.
      #
      # @return array
      attr_accessor :raw_server_data

      public

      # Returns an item from the _SERVER array.
      #
      # If the value does not exist in the array, null is returned.
      #
      # @param [String] value_name
      # @return [String, nil]
      def raw_server_value(value_name)
        @raw_server_data[value_name]
      end

      # Sets the _SERVER array.
      #
      # @param array data
      # @return [void]
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
