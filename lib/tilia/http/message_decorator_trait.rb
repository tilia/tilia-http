module Tilia
  module Http
    # This trait contains a bunch of methods, shared by both the RequestDecorator
    # and the ResponseDecorator.
    #
    # Didn't seem needed to create a full class for this, so we're just
    # implementing it as a trait.
    module MessageDecoratorTrait
      # (see MessageInterface#body_as_stream)
      def body_as_stream
        @inner.body_as_stream
      end

      # (see MessageInterface#body_as_string)
      def body_as_string
        @inner.body_as_string
      end

      # (see MessageInterface#body)
      def body
        @inner.body
      end

      # (see MessageInterface#body=)
      def body=(body)
        @inner.body = body
      end

      # (see MessageInterface#headers)
      def headers
        @inner.headers
      end

      # (see MessageInterface#header?)
      def header?(name)
        @inner.header?(name)
      end

      # (see MessageInterface#header)
      def header(name)
        @inner.header(name)
      end

      # (see MessageInterface#header_as_array)
      def header_as_array(name)
        @inner.header_as_array(name)
      end

      # (see MessageInterface#update_header)
      def update_header(name, value)
        @inner.update_header(name, value)
      end

      # (see MessageInterface#update_headers)
      def update_headers(headers)
        @inner.update_headers(headers)
      end

      # (see MessageInterface#add_header)
      def add_header(name, value)
        @inner.add_header(name, value)
      end

      # (see MessageInterface#add_headers)
      def add_headers(headers)
        @inner.add_headers(headers)
      end

      # (see MessageInterface#remove_header)
      def remove_header(name)
        @inner.remove_header(name)
      end

      # (see MessageInterface#http_version=)
      def http_version=(version)
        @inner.http_version = version
      end

      # (see MessageInterface#http_version)
      def http_version
        @inner.http_version
      end
    end
  end
end
