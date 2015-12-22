# TODO: document
module Tilia
  module Http
    class ClientMock < Client
      # RUBY: attr_accessor :persisted_settings

      # Making this method public.
      #
      # We are also going to persist all settings this method generates. While
      # the underlying object doesn't behave exactly the same, it helps us
      # simulate what curl does internally, and helps us identify problems with
      # settings that are set by _some_ methods and not correctly reset by other
      # methods after subsequent use.
      # forces
      def create_curl_settings_array(request)
        settings = super(request)
        settings = @persisted_settings.merge(settings)
        @persisted_settings = settings
        settings
      end

      # Making this method public.
      def parse_curl_result(curl_handle)
        super(curl_handle)
      end

      # This method is responsible for performing a single request.
      #
      # @param RequestInterface request
      # @return [ResponseInterface]
      def do_request(request)
        response = nil

        do_request_arguments = DoRequestArguments.new(request, response)
        emit('doRequest', [do_request_arguments])
        (request, response) = do_request_arguments.to_a

        # If nothing modified response, we're using the default behavior.
        if response.nil?
          super(request)
        else
          response
        end
      end

      protected

      # Returns a bunch of information about a curl request.
      #
      # This method exists so it can easily be overridden and mocked.
      #
      # @param resource curl_handle
      # @return array
      def curl_stuff(curl_handle)
        to_return = nil
        curl_stuff_arguments = CurlStuffArguments.new(to_return)
        emit('curlStuff', [curl_stuff_arguments])
        (to_return,) = curl_stuff_arguments.to_a

        # If nothing modified return, we're using the default behavior.
        if to_return.nil?
          super(curl_handle)
        else
          to_return
        end
      end

      # Calls curl_exec
      #
      # This method exists so it can easily be overridden and mocked.
      #
      # @param resource curl_handle
      # @return [String]
      def curl_exec(curl_handle, request)
        to_return = nil
        curl_exec_arguments = CurlExecArguments.new(to_return)
        emit('curlExec', [curl_exec_arguments])
        (to_return,) = curl_exec_arguments.to_a

        # If nothing modified return, we're using the default behavior.
        if to_return.nil?
          super(curl_handle, request)
        else
          to_return
        end
      end

      public

      # TODO: document
      def initialize
        @persisted_settings = {}
        super
      end

      DoRequestArguments = Struct.new(:request, :response)
      CurlStuffArguments = Struct.new(:return)
      CurlExecArguments = Struct.new(:curl_handle)
    end
  end
end
