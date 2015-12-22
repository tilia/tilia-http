require 'test_helper'
require 'http/sapi_mock'

module Tilia
  module Http
    class RequestTest < Minitest::Test
      def test_construct
        request = Request.new('GET', '/foo', 'User-Agent' => 'Evert')
        assert_equal('GET', request.method)
        assert_equal('/foo', request.url)
        assert_equal({ 'User-Agent' => ['Evert'] }, request.headers)
      end

      def test_get_query_parameters
        request = Request.new('GET', '/foo?a=b&c&d=e')
        assert_equal(
          {
            'a' => 'b',
            'c' => nil,
            'd' => 'e'
          },
          request.query_parameters
        )
      end

      def test_get_query_parameters_no_data
        request = Request.new('GET', '/foo')
        assert_equal({}, request.query_parameters)
      end

      def test_create_from_php_request
        sapi = SapiMock.new('REQUEST_METHOD' => 'PUT')

        request = sapi.request
        assert_equal('PUT', request.method)
      end

      def test_get_absolute_url
        s = {
          'HTTP_HOST'   => 'sabredav.org',
          'REQUEST_URI' => '/foo'
        }

        r = Sapi.create_from_server_array(s)

        assert_equal('http://sabredav.org/foo', r.absolute_url)

        s = {
          'HTTP_HOST'   => 'sabredav.org',
          'REQUEST_URI' => '/foo',
          'HTTPS'       => 'on'
        }

        r = Sapi.create_from_server_array(s)

        assert_equal('https://sabredav.org/foo', r.absolute_url)
      end

      def test_get_post_data
        post = { 'bla' => 'foo' }
        r = Request.new
        r.post_data = post
        assert_equal(post, r.post_data)
      end

      def test_get_path
        request = Request.new
        request.base_url = '/foo'
        request.url = '/foo/bar/'

        assert_equal('bar', request.path)
      end

      def test_get_path_stripped_query
        request = Request.new
        request.base_url = '/foo'
        request.url = '/foo/bar/?a=b'

        assert_equal('bar', request.path)
      end

      def test_get_path_missing_slash
        request = Request.new
        request.base_url = '/foo/'
        request.url = '/foo'

        assert_equal('', request.path)
      end

      def test_get_path_outside_base_url
        request = Request.new
        request.base_url = '/foo/'
        request.url = '/bar/'

        assert_raises(RuntimeError) { request.path }
      end

      def test_to_string
        request = Request.new('PUT', '/foo/bar', 'Content-Type' => 'text/xml')
        request.body = 'foo'

        expected = <<HI
PUT /foo/bar HTTP/1.1\r
Content-Type: text/xml\r
\r
foo
HI
        expected.chomp!
        assert_equal(expected, request.to_s)
      end

      def test_to_string_authorization
        request = Request.new('PUT', '/foo/bar', 'Content-Type' => 'text/xml', 'Authorization' => 'Basic foobar')
        request.body = 'foo'

        expected = <<HI
PUT /foo/bar HTTP/1.1\r
Content-Type: text/xml\r
Authorization: Basic REDACTED\r
\r
foo
HI
        expected.chomp!
        assert_equal(expected, request.to_s)
      end

      def test_constructor_with_array
        assert_raises(ArgumentError) { Request.new([]) }
      end
    end
  end
end
