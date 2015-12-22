module Tilia
  module Http
    # An exception representing a HTTP error.
    #
    # This can be used as a generic exception in your application, if you'd like
    # to map HTTP errors to exceptions.
    #
    # If you'd like to use this, create a new exception class, extending Exception
    # and implementing this interface.
    class HttpException < Exception
      # The http status code for the error.
      #
      # This may either be just the number, or a number and a human-readable
      # message, separated by a space.
      #
      # @return [String, nil]
      def http_status
      end
    end
  end
end
