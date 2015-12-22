require 'test_helper'

module Tilia
  module Http
    class RequestDecoratorTest < Minitest::Test
      def setup
        @inner = Request.new
        @outer = RequestDecorator.new(@inner)
      end

      def test_method
        @outer.method = 'FOO'
        assert_equal('FOO', @inner.method)
        assert_equal('FOO', @outer.method)
      end

      def test_url
        @outer.url = '/foo'
        assert_equal('/foo', @inner.url)
        assert_equal('/foo', @outer.url)
      end

      def test_absolute_url
        @outer.absolute_url = 'http://example.org/foo'
        assert_equal('http://example.org/foo', @inner.absolute_url)
        assert_equal('http://example.org/foo', @outer.absolute_url)
      end

      def test_base_url
        @outer.base_url = '/foo'
        assert_equal('/foo', @inner.base_url)
        assert_equal('/foo', @outer.base_url)
      end

      def test_path
        @outer.base_url = '/foo'
        @outer.url = '/foo/bar'
        assert_equal('bar', @inner.path)
        assert_equal('bar', @outer.path)
      end

      def test_query_params
        @outer.url = '/foo?a=b&c=d&e'
        expected = {
          'a' => 'b',
          'c' => 'd',
          'e' => nil
        }

        assert_equal(expected, @inner.query_parameters)
        assert_equal(expected, @outer.query_parameters)
      end

      def test_post_data
        post_data = {
          'a' => 'b',
          'c' => 'd',
          'e' => nil
        }

        @outer.post_data = post_data
        assert_equal(post_data, @outer.post_data)
        assert_equal(post_data, @inner.post_data)
      end

      def test_server_data
        server_data = { 'HTTPS' => 'On' }

        @outer.raw_server_data = server_data
        assert_equal('On', @inner.raw_server_value('HTTPS'))
        assert_equal('On', @outer.raw_server_value('HTTPS'))

        assert_nil(@inner.raw_server_value('FOO'))
        assert_nil(@outer.raw_server_value('FOO'))
      end

      def test_to_string
        @inner.method = 'POST'
        @inner.url = '/foo/bar/'
        @inner.body = 'foo'
        @inner.update_header('foo', 'bar')

        assert_equal(@inner.to_s, @outer.to_s)
      end
    end
  end
end
