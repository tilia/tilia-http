require 'stringio'
module Tilia
  module Http
    # This is the abstract base class for both the Request and Response objects.
    #
    # This object contains a few simple methods that are shared by both.
    module Message
      include Tilia::Http::MessageInterface

      # (see MessageInterface#body_as_stream)
      def body_as_stream
        body = @body
        if body.is_a?(String) || body.nil?
          stream = StringIO.new
          stream.write body
          stream.rewind
          return stream
        end
        body
      end

      # (see MessageInterface#body_as_string)
      def body_as_string
        body = @body
        if body.is_a?(String)
          body
        elsif body.nil?
          ''
        else
          content_length = header('Content-Length')

          if content_length.present?
            body.read(content_length.to_i)
          else
            body.read
          end
        end
      end

      # (see MessageInterface#body)
      attr_reader :body

      # (see MessageInterface#body=)
      attr_writer :body

      # (see MessageInterface#headers)
      def headers
        result = {}
        @headers.values.each do |header_info|
          result[header_info[0]] = header_info[1]
        end
        result
      end

      # (see MessageInterface#header?)
      def header?(name)
        @headers.key? name.downcase
      end

      # (see MessageInterface#header)
      def header(name)
        name = name.downcase

        return @headers[name][1].join(',') if @headers.key?(name)

        nil
      end

      # (see MessageInterface#header_as_array)
      def header_as_array(name)
        name = name.downcase

        return @headers[name][1] if @headers.key?(name)

        []
      end

      # (see MessageInterface#update_header)
      def update_header(name, value)
        value = [value] unless value.is_a?(Array)
        @headers[name.downcase] = [name, value]
      end

      # (see MessageInterface#update_headers)
      def update_headers(headers)
        headers.each do |name, value|
          update_header(name, value)
        end
      end

      # (see MessageInterface#add_header)
      def add_header(name, value)
        l_name = name.downcase
        value = [value] unless value.is_a?(Array)

        if @headers.key?(l_name)
          @headers[l_name][1].concat value
        else
          @headers[l_name] = [name, value]
        end
      end

      # (see MessageInterface#add_headers)
      def add_headers(headers)
        headers.each do |name, value|
          add_header(name, value)
        end
      end

      # (see MessageInterface#remove_header)
      def remove_header(name)
        name = name.downcase
        return false unless @headers.key?(name)
        @headers.delete name
        true
      end

      # (see MessageInterface#http_version)
      attr_writer :http_version

      # (see MessageInterface#http_version=)
      attr_reader :http_version

      # Initializes the instance vars of Message
      def initialize(*args)
        @body = nil
        @headers = {}
        @http_version = '1.1'

        super
      end

      # creates a deep copy of the headers hash when cloning
      def initialize_copy(_original)
        @headers = @headers.deep_dup
      end
    end
  end
end
