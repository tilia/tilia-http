require 'test_helper'

module Tilia
  module Http
    class ResponseTest < Minitest::Test
      def test_construct
        response = Response.new(200, 'Content-Type' => 'text/xml')
        assert_equal(200, response.status)
        assert_equal('OK', response.status_text)
      end

      def test_set_status
        response = Response.new
        response.status = '402 Where\'s my money?'
        assert_equal(402, response.status)
        assert_equal('Where\'s my money?', response.status_text)
      end

      def test_invalid_status
        assert_raises(ArgumentError) { Response.new(1000) }
      end

      def test_to_string
        response = Response.new(200, 'Content-Type' => 'text/xml')
        response.body = 'foo'

        expected = <<HI
HTTP/1.1 200 OK\r
Content-Type: text/xml\r
\r
foo
HI
        expected.chomp!
        assert_equal(expected, response.to_s)
      end
    end
  end
end
