module Tilia
  module Http
    # A rudimentary HTTP client.
    #
    # This object wraps PHP's curl extension and provides an easy way to send it a
    # Request object, and return a Response object.
    #
    # This is by no means intended as the next best HTTP client, but it does the
    # job and provides a simple integration with the rest of sabre/http.
    #
    # This client emits the following events:
    #   before_request(RequestInterface request)
    #   after_request(RequestInterface request, ResponseInterface response)
    #   error(RequestInterface request, ResponseInterface response, bool &retry, int retry_count)
    #   exception(RequestInterface request, ClientException e, bool &retry, int retry_count)
    #
    # The beforeRequest event allows you to do some last minute changes to the
    # request before it's done, such as adding authentication headers.
    #
    # The afterRequest event will be emitted after the request is completed
    # succesfully.
    #
    # If a HTTP error is returned (status code higher than 399) the error event is
    # triggered. It's possible using this event to retry the request, by setting
    # retry to true.
    #
    # The amount of times a request has retried is passed as retry_count, which
    # can be used to avoid retrying indefinitely. The first time the event is
    # called, this will be 0.
    #
    # It's also possible to intercept specific http errors, by subscribing to for
    # example 'error:401'.
    class Client < Tilia::Event::EventEmitter
      # Initializes the client.
      #
      # @return [void]
      def initialize
        super

        @hydra = nil
        @throw_exceptions = false
        @max_redirects = 5
        @curl_settings = {
          header: false, # RUBY otherwise header will be part of response.body
          nobody: false,
          useragent: "tilia-http/#{Version::VERSION} (http://sabre.io/)"
        }
        @client_map = {}
      end

      # Sends a request to a HTTP server, and returns a response.
      #
      # @param [RequestInterface] request
      # @return [ResponseInterface]
      def send_request(request)
        emit('beforeRequest', [request])

        retry_count = 0
        redirects = 0

        response = nil
        code = 0

        loop do
          do_redirect = false
          do_retry = false

          begin
            response = do_request(request)

            code = response.status.to_i

            # We are doing in-PHP redirects, because curl's
            # FOLLOW_LOCATION throws errors when PHP is configured with
            # open_basedir.
            #
            # https://github.com/fruux/sabre-http/issues/12
            if [301, 302, 307, 308].include?(code) && redirects < @max_redirects
              old_location = request.url

              # Creating a new instance of the request object.
              request = request.clone

              # Setting the new location
              request.set_url(
                Tilia::Uri.resolve(
                  old_location,
                  response.header('Location')
                )
              )

              do_redirect = true
              redirects += 1
            end

            # This was a HTTP error
            if code >= 400
              box = Box.new(do_retry)
              emit('error', [request, response, box, retry_count])
              emit("error:#{code}", [request, response, box, retry_count])
              do_retry = box.value
            end
          rescue Tilia::Http::ClientException => e
            box = Box.new(do_retry)
            emit('exception', [request, e, box, retry_count])
            do_retry = box.value

            # If retry was still set to false, it means no event handler
            # dealt with the problem. In this case we just re-throw the
            # exception.
            raise e unless do_retry
          end

          retry_count += 1 if do_retry

          break unless do_retry || do_redirect
        end

        emit('afterRequest', [request, response])

        fail Tilia::Http::ClientHttpException.new(response), 'Oh oh' if @throw_exceptions && code >= 400

        response
      end

      # Sends a HTTP request asynchronously.
      #
      # Due to the nature of PHP, you must from time to time poll to see if any
      # new responses came in.
      #
      # After calling sendAsync, you must therefore occasionally call the poll
      # method, or wait.
      #
      # @param [RequestInterface] request
      # @param [#call] success
      # @param [#call] error
      # @return [void]
      def send_async(request, success = nil, error = nil)
        emit('beforeRequest', [request])

        send_async_internal(request, success, error)
        poll
      end

      # This method checks if any http requests have gotten results, and if so,
      # call the appropriate success or error handlers.
      #
      # This method will return true if there are still requests waiting to
      # return, and false if all the work is done.
      #
      # @return [Boolean]
      def poll
        # nothing to do?
        return false if @client_map.empty?

        # Hydra finishes them all
        @hydra.run

        @client_map.keys.each do |handler|
          (
            request,
            success_callback,
            error_callback,
            retry_count,
          ) = @client_map[handler]
          @client_map.delete handler

          curl_result = parse_curl_result(handler)
          do_retry = false

          if curl_result['status'] == STATUS_CURLERROR
            e = Exception.new

            box = Box.new(do_retry)
            emit('exception', [request, e, box, retry_count])
            do_retry = box.value

            if do_retry
              retry_count += 1
              send_async_internal(request, success_callback, error_callback, retry_count)
              next
            end

            curl_result['request'] = request

            error_callback.call(curl_result) if error_callback
          elsif curl_result['status'] == STATUS_HTTPERROR
            box = Box.new(do_retry)
            emit('error', [request, curl_result['response'], box, retry_count])
            emit("error:#{curl_result['http_code']}", [request, curl_result['response'], box, retry_count])
            do_retry = box.value

            if do_retry
              retry_count += 1
              send_async_internal(request, success_callback, error_callback, retry_count)
              next
            end

            curl_result['request'] = request

            error_callback.call(curl_result) if error_callback
          else
            emit('afterRequest', [request, curl_result['response']])

            success_callback.call(curl_result['response']) if success_callback
          end

          break if @client_map.empty?
        end

        @client_map.any?
      end

      # Processes every HTTP request in the queue, and waits till they are all
      # completed.
      #
      # @return [void]
      def wait
        loop do
          still_running = poll
          break unless still_running
        end
      end

      # If this is set to true, the Client will automatically throw exceptions
      # upon HTTP errors.
      #
      # This means that if a response came back with a status code greater than
      # or equal to 400, we will throw a ClientHttpException.
      #
      # This only works for the send method. Throwing exceptions for
      # send_async is not supported.
      #
      # @return [Boolean]
      attr_writer :throw_exceptions

      # Adds a CURL setting.
      #
      # These settings will be included in every HTTP request.
      #
      # @param [Symbol] name
      # @param value
      # @return [void]
      def add_curl_setting(name, value)
        @curl_settings[name] = value
      end

      protected

      # This method is responsible for performing a single request.
      #
      # @param [RequestInterface] request
      # @return [ResponseInterface]
      def do_request(request)
        client = create_client(request)
        client.run

        response = parse_curl_result(client)

        if response['status'] == STATUS_CURLERROR
          fail Tilia::Http::ClientException.new(response['curl_errno']), response['curl_errmsg']
        end

        response['response']
      end

      public

      STATUS_SUCCESS = 0
      STATUS_CURLERROR = 1
      STATUS_HTTPERROR = 2

      # Parses the result of a curl call in a format that's a bit more
      # convenient to work with.
      #
      # The method returns an array with the following elements:
      #   * status - one of the 3 STATUS constants.
      #   * curl_errno - A curl error number. Only set if status is
      #                  STATUS_CURLERROR.
      #   * curl_errmsg - A current error message. Only set if status is
      #                   STATUS_CURLERROR.
      #   * response - Response object. Only set if status is STATUS_SUCCESS, or
      #                STATUS_HTTPERROR.
      #   * http_code - HTTP status code, as an int. Only set if Only set if
      #                 status is STATUS_SUCCESS, or STATUS_HTTPERROR
      #
      # @param [Typhoeus::Request] client
      # @return [Response]
      def parse_curl_result(client)
        client_response = client.response
        unless client_response.return_code == :ok
          return {
            'status'      => STATUS_CURLERROR,
            'curl_errno'  => client_response.return_code,
            'curl_errmsg' => client_response.return_message
          }
        end

        header_blob = client_response.response_headers
        # In the case of 204 No Content, strlen(response) == curl_info['header_size].
        # This will cause substr(response, curl_info['header_size']) return FALSE instead of NULL
        # An exception will be thrown when calling getBodyAsString then
        response_body = client_response.body
        response_body = nil if response_body == ''

        # In the case of 100 Continue, or redirects we'll have multiple lists
        # of headers for each separate HTTP response. We can easily split this
        # because they are separated by \r\n\r\n
        header_blob = header_blob.strip.split(/\r?\n\r?\n/)

        # We only care about the last set of headers
        header_blob = header_blob[-1]

        # Splitting headers
        header_blob = header_blob.split(/\r?\n/)

        response = Tilia::Http::Response.new
        response.status = client_response.code

        header_blob.each do |header|
          parts = header.split(':', 2)

          response.add_header(parts[0].strip, parts[1].strip) if parts.size == 2
        end

        response.body = response_body

        http_code = response.status.to_i

        {
          'status'    => http_code >= 400 ? STATUS_HTTPERROR : STATUS_SUCCESS,
          'response'  => response,
          'http_code' => http_code
        }
      end

      # Sends an asynchronous HTTP request.
      #
      # We keep this in a separate method, so we can call it without triggering
      # the beforeRequest event and don't do the poll.
      #
      # @param [RequestInterface] request
      # @param [#call] success
      # @param [#call] error
      # @param [Integer] retry_count
      def send_async_internal(request, success, error, retry_count = 0)
        @hydra = Typhoeus::Hydra.hydra unless @hydra

        client = create_client(request)
        @hydra.queue client

        @client_map[client] = [
          request,
          success,
          error,
          retry_count
        ]
      end

      # TODO: document
      def create_client(request)
        settings = {}
        @curl_settings.each do |key, value|
          settings[key] = value
        end

        case request.method
        when 'HEAD'
          settings[:nobody] = true
          settings[:method] = :head
          settings[:postfields] = ''
          settings[:put] = false
        when 'GET'
          settings[:method] = :get
          settings[:postfields] = ''
          settings[:put] = false
        else
          settings[:method] = request.method.downcase.to_sym
          body = request.body
          if !body.is_a?(String) && !body.nil?
            settings[:put] = true
            settings[:infile] = body
          else
            settings[:postfields] = body.to_s
          end
        end

        settings[:headers] = {}
        request.headers.each do |key, values|
          settings[:headers][key] = values.join("\n")
        end
        settings[:protocols] = [:http, :https]
        settings[:redir_protocols] = [:http, :https]

        client = Typhoeus::Request.new(request.url, settings)
        client
      end
    end

    # Class to fix rubys real-world "pass-by-reference" shortcommings
    class Box
      attr_accessor :value

      def initialize(v = nil)
        @value = v
      end
    end
  end
end
