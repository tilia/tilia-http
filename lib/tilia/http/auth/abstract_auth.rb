module Tilia
  module Http
    module Auth
      # HTTP Authentication base class.
      #
      # This class provides some common functionality for the various base classes.
      class AbstractAuth
        # Creates the object
        #
        # @param [String] realm
        # @return [void]
        def initialize(realm = 'TiliaTooth', request, response)
          @realm = realm
          @request = request
          @response = response
        end

        # This method sends the needed HTTP header and statuscode (401) to force
        # the user to login.
        #
        # @return [void]
        def require_login
        end

        # Returns the HTTP realm
        #
        # @return [String]
        attr_reader :realm
      end
    end
  end
end
