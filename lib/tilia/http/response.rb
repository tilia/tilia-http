module Tilia
  module Http
    # This class represents a single HTTP response.
    class Response
      include Tilia::Http::Message
      include Tilia::Http::ResponseInterface

      # This is the list of currently registered HTTP status codes.
      #
      # @return array
      def self.status_codes
        {
          100 => 'Continue',
          101 => 'Switching Protocols',
          102 => 'Processing',
          200 => 'OK',
          201 => 'Created',
          202 => 'Accepted',
          203 => 'Non-Authorative Information',
          204 => 'No Content',
          205 => 'Reset Content',
          206 => 'Partial Content',
          207 => 'Multi-Status', # RFC 4918
          208 => 'Already Reported', # RFC 5842
          226 => 'IM Used', # RFC 3229
          300 => 'Multiple Choices',
          301 => 'Moved Permanently',
          302 => 'Found',
          303 => 'See Other',
          304 => 'Not Modified',
          305 => 'Use Proxy',
          307 => 'Temporary Redirect',
          308 => 'Permanent Redirect',
          400 => 'Bad Request',
          401 => 'Unauthorized',
          402 => 'Payment Required',
          403 => 'Forbidden',
          404 => 'Not Found',
          405 => 'Method Not Allowed',
          406 => 'Not Acceptable',
          407 => 'Proxy Authentication Required',
          408 => 'Request Timeout',
          409 => 'Conflict',
          410 => 'Gone',
          411 => 'Length Required',
          412 => 'Precondition failed',
          413 => 'Request Entity Too Large',
          414 => 'Request-URI Too Long',
          415 => 'Unsupported Media Type',
          416 => 'Requested Range Not Satisfiable',
          417 => 'Expectation Failed',
          418 => 'I\'m a teapot', # RFC 2324
          421 => 'Misdirected Request', # RFC7540 (HTTP/2)
          422 => 'Unprocessable Entity', # RFC 4918
          423 => 'Locked', # RFC 4918
          424 => 'Failed Dependency', # RFC 4918
          426 => 'Upgrade Required',
          428 => 'Precondition Required', # RFC 6585
          429 => 'Too Many Requests', # RFC 6585
          431 => 'Request Header Fields Too Large', # RFC 6585
          451 => 'Unavailable For Legal Reasons', # draft-tbray-http-legally-restricted-status
          500 => 'Internal Server Error',
          501 => 'Not Implemented',
          502 => 'Bad Gateway',
          503 => 'Service Unavailable',
          504 => 'Gateway Timeout',
          505 => 'HTTP Version not supported',
          506 => 'Variant Also Negotiates',
          507 => 'Insufficient Storage', # RFC 4918
          508 => 'Loop Detected', # RFC 5842
          509 => 'Bandwidth Limit Exceeded', # non-standard
          510 => 'Not extended',
          511 => 'Network Authentication Required' # RFC 6585
        }
      end

      # Creates the response object
      #
      # @param [String, Fixnum] status
      # @param [Hash] headers
      # @param [String, IO] body
      # @return [void]
      def initialize(status = nil, headers = nil, body = nil)
        super()

        self.status = status if status # Don't set @status directly!
        update_headers(headers) if headers
        @body = body if body
      end

      # (see ResponseInterface#status)
      attr_reader :status

      # (see ResponseInterface#status_text)
      attr_reader :status_text

      # (see ResponseInterface#status=)
      def status=(status)
        if status.is_a?(Fixnum) || status =~ /^\d+$/
          status_code = status
          status_text = Response.status_codes.key?(status.to_i) ? Response.status_codes[status.to_i] : 'Unkown'
        else
          (
            status_code,
            status_text
          ) = status.split(' ', 2)
        end

        status_code = status_code.to_i unless status_code.is_a?(Fixnum)

        fail ArgumentError, 'The HTTP status code must be exactly 3 digits' if status_code < 100 || status_code > 999

        @status = status_code
        @status_text = status_text
      end

      # Serializes the response object as a string.
      #
      # This is useful for debugging purposes.
      #
      # @return [String]
      def to_s
        str = "HTTP/#{http_version} #{status} #{status_text}\r\n"
        headers.each do |key, value|
          value.each do |v|
            str << "#{key}: #{v}\r\n"
          end
        end

        str << "\r\n"
        str << body_as_string
        str
      end
    end
  end
end
