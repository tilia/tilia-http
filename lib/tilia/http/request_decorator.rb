module Tilia
  module Http
    # Request Decorator
    #
    # This helper class allows you to easily create decorators for the Request
    # object.
    class RequestDecorator
      include Tilia::Http::RequestInterface
      include Tilia::Http::MessageDecoratorTrait

      # Constructor.
      #
      # @param [RequestInterface] inner
      def initialize(inner)
        @inner = inner
      end

      # (see RequestInterface#method)
      def method
        @inner.method
      end

      # (see RequestInterface#method=)
      def method=(method)
        @inner.method = method
      end

      # (see RequestInterface#url)
      def url
        @inner.url
      end

      # (see RequestInterface#url=)
      def url=(url)
        @inner.url = url
      end

      # (see RequestInterface#absolute_url)
      def absolute_url
        @inner.absolute_url
      end

      # (see RequestInterface#absolute_url=)
      def absolute_url=(url)
        @inner.absolute_url = url
      end

      # (see RequestInterface#base_url)
      def base_url
        @inner.base_url
      end

      # (see RequestInterface#base_url=)
      def base_url=(url)
        @inner.base_url = url
      end

      # (see RequestInterface#path)
      def path
        @inner.path
      end

      # (see RequestInterface#query_parameters)
      def query_parameters
        @inner.query_parameters
      end

      # (see RequestInterface#post_data)
      def post_data
        @inner.post_data
      end

      # (see RequestInterface#post_data=)
      def post_data=(post_data)
        @inner.post_data = post_data
      end

      # (see RequestInterface#raw_server_value)
      def raw_server_value(value_name)
        @inner.raw_server_value(value_name)
      end

      # (see RequestInterface#raw_server_data=)
      def raw_server_data=(data)
        @inner.raw_server_data = data
      end

      # Serializes the request object as a string.
      #
      # This is useful for debugging purposes.
      #
      # @return [String]
      def to_s
        @inner.to_s
      end
    end
  end
end
