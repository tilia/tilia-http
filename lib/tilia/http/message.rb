require 'stringio'
module Tilia
  module Http
    # This is the abstract base class for both the Request and Response objects.
    #
    # This object contains a few simple methods that are shared by both.
    module Message
      include Tilia::Http::MessageInterface

      protected

      # Request body
      #
      # This should be a stream resource
      #
      # @return resource
      attr_accessor :body

      # Contains the list of HTTP headers
      #
      # @return array
      attr_accessor :headers

      # HTTP message version (1.0 or 1.1)
      #
      # @return [String]
      attr_accessor :http_version

      public

      # Returns the body as a readable stream resource.
      #
      # Note that the stream may not be rewindable, and therefore may only be
      # read once.
      #
      # @return resource
      def body_as_stream
        body = self.body
        if body.is_a?(String) || body.nil?
          stream = StringIO.new
          stream.write body
          stream.rewind
          return stream
        end
        body
      end

      # Returns the body as a string.
      #
      # Note that because the underlying data may be based on a stream, this
      # method could only work correctly the first time.
      #
      # @return [String]
      def body_as_string
        body = self.body
        if body.is_a?(String)
          body
        elsif body.nil?
          ''
        else
          body.read
        end
      end

      # Returns the message body, as it's internal representation.
      #
      # This could be either a string or a stream.
      #
      # @return resource|string
      def body
        @body
      end

      # Replaces the body resource with a new stream or string.
      #
      # @param resource|string body
      def body=(body)
        @body = body
      end

      # Returns all the HTTP headers as an array.
      #
      # Every header is returned as an array, with one or more values.
      #
      # @return array
      def headers
        result = {}
        @headers.values.each do |header_info|
          result[header_info[0]] = header_info[1]
        end
        result
      end

      # Will return true or false, depending on if a HTTP header exists.
      #
      # @param [String] name
      # @return bool
      def header?(name)
        @headers.key? name.downcase
      end

      # Returns a specific HTTP header, based on it's name.
      #
      # The name must be treated as case-insensitive.
      # If the header does not exist, this method must return null.
      #
      # If a header appeared more than once in a HTTP request, this method will
      # concatenate all the values with a comma.
      #
      # Note that this not make sense for all headers. Some, such as
      # `Set-Cookie` cannot be logically combined with a comma. In those cases
      # you *should* use header_as_array.
      #
      # @param [String] name
      # @return [String, nil]
      def header(name)
        name = name.downcase

        return @headers[name][1].join(',') if @headers.key?(name)

        nil
      end

      # Returns a HTTP header as an array.
      #
      # For every time the HTTP header appeared in the request or response, an
      # item will appear in the array.
      #
      # If the header did not exists, this method will return an empty array.
      #
      # @param [String] name
      # @return [String][]
      def header_as_array(name)
        name = name.downcase

        return @headers[name][1] if @headers.key?(name)

        []
      end

      # Updates a HTTP header.
      #
      # The case-sensitity of the name value must be retained as-is.
      #
      # If the header already existed, it will be overwritten.
      #
      # @param [String] name
      # @param [String, Array<String>] value
      # @return [void]
      def update_header(name, value)
        value = [value] unless value.is_a?(Array)
        @headers[name.downcase] = [name, value]
      end

      # Sets a new set of HTTP headers.
      #
      # The headers array should contain headernames for keys, and their value
      # should be specified as either a string or an array.
      #
      # Any header that already existed will be overwritten.
      #
      # @param array headers
      # @return [void]
      def update_headers(headers)
        headers.each do |name, value|
          update_header(name, value)
        end
      end

      # Adds a HTTP header.
      #
      # This method will not overwrite any existing HTTP header, but instead add
      # another value. Individual values can be retrieved with
      # getHeadersAsArray.
      #
      # @param [String] name
      # @param [String] value
      # @return [void]
      def add_header(name, value)
        l_name = name.downcase
        value = [value] unless value.is_a?(Array)

        if @headers.key?(l_name)
          @headers[l_name][1].concat value
        else
          @headers[l_name] = [name, value]
        end
      end

      # Adds a new set of HTTP headers.
      #
      # Any existing headers will not be overwritten.
      #
      # @param array headers
      # @return [void]
      def add_headers(headers)
        headers.each do |name, value|
          add_header(name, value)
        end
      end

      # Removes a HTTP header.
      #
      # The specified header name must be treated as case-insenstive.
      # This method should return true if the header was successfully deleted,
      # and false if the header did not exist.
      #
      # @return bool
      def remove_header(name)
        name = name.downcase
        return false unless @headers.key?(name)
        @headers.delete name
        true
      end

      # Sets the HTTP version.
      #
      # Should be 1.0 or 1.1.
      #
      # @param [String] version
      # @return [void]
      def http_version=(version)
        @http_version = version
      end

      # Returns the HTTP version.
      #
      # @return [String]
      def http_version
        @http_version
      end

      # TODO: document
      def initialize_message
        @body = nil
        @headers = {}
        @http_version = '1.1'
      end

      # TODO: document
      def initialize_copy(_original)
        @headers = @headers.deep_dup
      end
    end
  end
end
