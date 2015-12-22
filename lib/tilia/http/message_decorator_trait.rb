module Tilia
  module Http
    # This trait contains a bunch of methods, shared by both the RequestDecorator
    # and the ResponseDecorator.
    #
    # Didn't seem needed to create a full class for this, so we're just
    # implementing it as a trait.
    module MessageDecoratorTrait

      protected

      # The inner request object.
      #
      # All method calls will be forwarded here.
      #
      # @return MessageInterface
      attr_accessor :inner

      public

      # Returns the body as a readable stream resource.
      #
      # Note that the stream may not be rewindable, and therefore may only be
      # read once.
      #
      # @return resource
      def body_as_stream
        @inner.body_as_stream
      end

      # Returns the body as a string.
      #
      # Note that because the underlying data may be based on a stream, this
      # method could only work correctly the first time.
      #
      # @return string
      def body_as_string
        @inner.body_as_string
      end

      # Returns the message body, as it's internal representation.
      #
      # This could be either a string or a stream.
      #
      # @return resource|string
      def body
        @inner.body
      end

      # Updates the body resource with a new stream.
      #
      # @param resource body
      # @return void
      def body=(body)
        @inner.body = body
      end

      # Returns all the HTTP headers as an array.
      #
      # Every header is returned as an array, with one or more values.
      #
      # @return array
      def headers
        @inner.headers
      end

      # Will return true or false, depending on if a HTTP header exists.
      #
      # @param string name
      # @return bool
      def header?(name)
        @inner.header?(name)
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
      # @param string name
      # @return string|null
      def header(name)
        @inner.header(name)
      end

      # Returns a HTTP header as an array.
      #
      # For every time the HTTP header appeared in the request or response, an
      # item will appear in the array.
      #
      # If the header did not exists, this method will return an empty array.
      #
      # @param string name
      # @return string[]
      def header_as_array(name)
        @inner.header_as_array(name)
      end

      # Updates a HTTP header.
      #
      # The case-sensitity of the name value must be retained as-is.
      #
      # If the header already existed, it will be overwritten.
      #
      # @param string name
      # @param string|string[] value
      # @return void
      def update_header(name, value)
        @inner.update_header(name, value)
      end

      # Sets a new set of HTTP headers.
      #
      # The headers array should contain headernames for keys, and their value
      # should be specified as either a string or an array.
      #
      # Any header that already existed will be overwritten.
      #
      # @param array headers
      # @return void
      def update_headers(headers)
        @inner.update_headers(headers)
      end

      # Adds a HTTP header.
      #
      # This method will not overwrite any existing HTTP header, but instead add
      # another value. Individual values can be retrieved with
      # getHeadersAsArray.
      #
      # @param string name
      # @param string value
      # @return void
      def add_header(name, value)
        @inner.add_header(name, value)
      end

      # Adds a new set of HTTP headers.
      #
      # Any existing headers will not be overwritten.
      #
      # @param array headers
      # @return void
      def add_headers(headers)
        @inner.add_headers(headers)
      end

      # Removes a HTTP header.
      #
      # The specified header name must be treated as case-insenstive.
      # This method should return true if the header was successfully deleted,
      # and false if the header did not exist.
      #
      # @return bool
      def remove_header(name)
        @inner.remove_header(name)
      end

      # Sets the HTTP version.
      #
      # Should be 1.0 or 1.1.
      #
      # @param string version
      # @return void
      def http_version=(version)
        @inner.http_version = version
      end

      # Returns the HTTP version.
      #
      # @return string
      def http_version
        @inner.http_version
      end
    end
  end
end
