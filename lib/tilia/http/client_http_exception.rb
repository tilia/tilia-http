module Tilia
  module Http
    # This exception represents a HTTP error coming from the Client.
    #
    # By default the Client will not emit these, this has to be explicitly enabled
    # with the setThrowExceptions method.
    class ClientHttpException < Tilia::Http::HttpException
      # Constructor
      #
      # @param [ResponseInterface] response
      def initialize(response)
        @response = response
      end

      # The http status code for the error.
      #
      # @return [Integer]
      def http_status
        @response.status
      end

      # Returns the full response object.
      #
      # @return [ResponseInterface]
      attr_reader :response
    end
  end
end
