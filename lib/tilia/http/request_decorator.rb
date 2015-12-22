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
      # @param RequestInterface inner
      def initialize(inner)
        @inner = inner
      end

      # Returns the current HTTP method
      #
      # @return string
      def method
        @inner.method
      end

      # Sets the HTTP method
      #
      # @param string method
      # @return void
      def method=(method)
        @inner.method = method
      end

      # Returns the request url.
      #
      # @return string
      def url
        @inner.url
      end

      # Sets the request url.
      #
      # @param string url
      # @return void
      def url=(url)
        @inner.url = url
      end

      # Returns the absolute url.
      #
      # @return string
      def absolute_url
        @inner.absolute_url
      end

      # Sets the absolute url.
      #
      # @param string url
      # @return void
      def absolute_url=(url)
        @inner.absolute_url = url
      end

      # Returns the current base url.
      #
      # @return string
      def base_url
        @inner.base_url
      end

      # Sets a base url.
      #
      # This url is used for relative path calculations.
      #
      # The base url should default to /
      #
      # @param string url
      # @return void
      def base_url=(url)
        @inner.base_url = url
      end

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
      # @return string
      def path
        @inner.path
      end

      # Returns the list of query parameters.
      #
      # This is equivalent to PHP's $_GET superglobal.
      #
      # @return array
      def query_parameters
        @inner.query_parameters
      end

      # Returns the POST data.
      #
      # This is equivalent to PHP's $_POST superglobal.
      #
      # @return array
      def post_data
        @inner.post_data
      end

      # Sets the post data.
      #
      # This is equivalent to PHP's $_POST superglobal.
      #
      # This would not have been needed, if POST data was accessible as
      # php://input, but unfortunately we need to special case it.
      #
      # @param array post_data
      # @return void
      def post_data=(post_data)
        @inner.post_data = post_data
      end

      # Returns an item from the _SERVER array.
      #
      # If the value does not exist in the array, null is returned.
      #
      # @param string value_name
      # @return string|null
      def raw_server_value(value_name)
        @inner.raw_server_value(value_name)
      end

      # Sets the _SERVER array.
      #
      # @param array data
      # @return void
      def raw_server_data=(data)
        @inner.raw_server_data = data
      end

      # Serializes the request object as a string.
      #
      # This is useful for debugging purposes.
      #
      # @return string
      def to_s
        @inner.to_s
      end
    end
  end
end
