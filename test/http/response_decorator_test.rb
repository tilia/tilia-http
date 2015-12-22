require 'test_helper'

module Tilia
  module Http
    class ResponseDecoratorTest < Minitest::Test
      def setup
        @inner = Response.new
        @outer = ResponseDecorator.new(@inner)
      end

      def test_status
        @outer.status = 201
        assert_equal(201, @inner.status)
        assert_equal(201, @outer.status)
        assert_equal('Created', @inner.status_text)
        assert_equal('Created', @outer.status_text)
      end

      def test_to_string
        @inner.status = 201
        @inner.body = 'foo'
        @inner.update_header('foo', 'bar')

        assert_equal(@inner.to_s, @outer.to_s)
      end
    end
  end
end
