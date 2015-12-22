module Tilia
  module Http
    # HTTP utility methods
    #
    # @deprecated All these functions moved to the Tilia::Http namespace
    module Util
      # Content negotiation
      #
      # @deprecated Use Tilia::Http::negotiate_content_type
      # @param [String, nil] accept_header_value
      # @param array available_options
      # @return [String, nil]
      def self.negotiate_content_type(accept_header_value, available_options)
        Http.negotiate_content_type(accept_header_value, available_options)
      end

      # Deprecated! Use negotiateContentType.
      #
      # @deprecated Use Tilia::Http::negotiate_content_type
      # @param [String, nil] accept_header
      # @param array available_options
      # @return [String, nil]
      def self.negotiate(accept_header_value, available_options)
        Http.negotiate_content_type(accept_header_value, available_options)
      end

      # Parses a RFC2616-compatible date string
      #
      # This method returns false if the date is invalid
      #
      # @deprecated Use Tilia::Http::parse_date
      # @param [String] date_header
      # @return bool|DateTime
      def self.parse_http_date(date_header)
        Http.parse_date(date_header)
      end

      # Transforms a DateTime object to HTTP's most common date format.
      #
      # We're serializing it as the RFC 1123 date, which, for HTTP must be
      # specified as GMT.
      #
      # @deprecated Use Tilia::Http::to_date
      # @param \DateTime date_time
      # @return [String]
      def self.to_http_date(date_time)
        Http.to_date(date_time)
      end
    end
  end
end
