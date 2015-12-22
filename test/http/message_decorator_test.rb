require 'test_helper'

module Tilia
  module Http
    class MessageDecoratorTest < Minitest::Test
      def setup
        @inner = Tilia::Http::Request.new
        @outer = Tilia::Http::RequestDecorator.new(@inner)
      end

      def test_body
        @outer.body = 'foo'
        assert_equal('foo', @inner.body_as_stream.readlines.join(''))
        assert_equal('foo', @outer.body_as_stream.readlines.join(''))
        assert_equal('foo', @inner.body_as_string)
        assert_equal('foo', @outer.body_as_string)
        assert_equal('foo', @inner.body)
        assert_equal('foo', @outer.body)
      end

      def test_headers
        @outer.update_headers('a' => 'b')

        assert_equal({ 'a' => ['b'] }, @inner.headers)
        assert_equal({ 'a' => ['b'] }, @outer.headers)

        @outer.update_headers('c' => 'd')

        assert_equal({ 'a' => ['b'], 'c' => ['d'] }, @inner.headers)
        assert_equal({ 'a' => ['b'], 'c' => ['d'] }, @outer.headers)

        @outer.add_headers('e' => 'f')

        assert_equal({ 'a' => ['b'], 'c' => ['d'], 'e' => ['f'] }, @inner.headers)
        assert_equal({ 'a' => ['b'], 'c' => ['d'], 'e' => ['f'] }, @outer.headers)
      end

      def test_header
        refute(@outer.header?('a'))
        refute(@inner.header?('a'))
        @outer.update_header('a', 'c')
        assert(@outer.header?('a'))
        assert(@inner.header?('a'))

        assert_equal('c', @inner.header('A'))
        assert_equal('c', @outer.header('A'))

        @outer.add_header('A', 'd')

        assert_equal(['c', 'd'], @inner.header_as_array('A'))
        assert_equal(['c', 'd'], @outer.header_as_array('A'))

        @outer.remove_header('a')

        assert_nil(@inner.header('A'))
        assert_nil(@outer.header('A'))
      end

      def test_http_version
        @outer.http_version = '1.0'

        assert_equal('1.0', @inner.http_version)
        assert_equal('1.0', @outer.http_version)
      end
    end
  end
end
