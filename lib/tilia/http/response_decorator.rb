module Tilia
  module Http
    # Response Decorator
    #
    # This helper class allows you to easily create decorators for the Response
    # object.
    class ResponseDecorator
      include Tilia::Http::ResponseInterface
      include Tilia::Http::MessageDecoratorTrait

      # Constructor.
      #
      # @param ResponseInterface inner
      def initialize(inner)
        @inner = inner
      end

      # Returns the current HTTP status code.
      #
      # @return int
      def status
        @inner.status
      end

      # Returns the human-readable status string.
      #
      # In the case of a 200, this may for example be 'OK'.
      #
      # @return string
      def status_text
        @inner.status_text
      end

      # Sets the HTTP status code.
      #
      # This can be either the full HTTP status code with human readable string,
      # for example: "403 I can't let you do that, Dave".
      #
      # Or just the code, in which case the appropriate default message will be
      # added.
      #
      # @param string|int status
      # @return void
      def status=(status)
        @inner.status = status
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
