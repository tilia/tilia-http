module Tilia
  module Http
    # This exception may be emitted by the HTTP\Client class, in case there was a
    # problem emitting the request.
    class ClientException < StandardError
      # TODO: document
      def initialize(code)
        @code = code.to_i
      end

      # TODO: document
      attr_accessor :code
    end
  end
end
