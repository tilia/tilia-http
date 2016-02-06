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
      # @param [ResponseInterface] inner
      def initialize(inner)
        @inner = inner
      end

      # (see ResponseInterface#status)
      def status
        @inner.status
      end

      # (see ResponseInterface#status_text)
      def status_text
        @inner.status_text
      end

      # (see ResponseInterface#status=)
      def status=(status)
        @inner.status = status
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
