module Tilia
  module Http
    # This interface represents a HTTP response.
    module ResponseInterface
      include Tilia::Http::MessageInterface

      # Returns the current HTTP status code.
      #
      # @return int
      def status
      end

      # Returns the human-readable status string.
      #
      # In the case of a 200, this may for example be 'OK'.
      #
      # @return [String]
      def status_text
      end

      # Sets the HTTP status code.
      #
      # This can be either the full HTTP status code with human readable string,
      # for example: "403 I can't let you do that, Dave".
      #
      # Or just the code, in which case the appropriate default message will be
      # added.
      #
      # @param [String, Fixnum] status
      # @throws \InvalidArgumentExeption
      # @return [void]
      def status=(_status)
      end
    end
  end
end
