require 'test_helper'
require 'base64'
require 'stringio'
require 'http/sapi_mock'

module Tilia
  module Http
    class SapiTest < Minitest::Test
      def test_construct_from_server_array
        request = Sapi.create_from_server_array(
          'PATH_INFO'    => '/foo',
          'REQUEST_METHOD'  => 'GET',
          'HTTP_USER_AGENT' => 'Evert',
          'CONTENT_TYPE'    => 'text/xml',
          'CONTENT_LENGTH'  => '400',
          'SERVER_PROTOCOL' => 'HTTP/1.0'
        )

        assert_equal('GET', request.method)
        assert_equal('/foo', request.url)
        assert_equal(
          {
            'User-Agent'     => ['Evert'],
            'Content-Type'   => ['text/xml'],
            'Content-Length' => ['400']
          },
          request.headers
        )

        assert_equal('1.0', request.http_version)

        assert_equal('400', request.raw_server_value('CONTENT_LENGTH'))
        assert_nil(request.raw_server_value('FOO'))
      end

      def test_construct_php_auth
        request = Sapi.create_from_server_array(
          'PATH_INFO'    => '/foo',
          'REQUEST_METHOD'  => 'GET',
          'PHP_AUTH_USER'   => 'user',
          'PHP_AUTH_PW'     => 'pass'
        )

        assert_equal('GET', request.method)
        assert_equal('/foo', request.url)
        assert_equal(
          {
            'Authorization' => ["Basic #{Base64.strict_encode64('user:pass')}"]
          },
          request.headers
        )
      end

      def test_construct_php_auth_digest
        request = Sapi.create_from_server_array(
          'PATH_INFO'    => '/foo',
          'REQUEST_METHOD'  => 'GET',
          'PHP_AUTH_DIGEST' => 'blabla'
        )

        assert_equal('GET', request.method)
        assert_equal('/foo', request.url)
        assert_equal(
          {
            'Authorization' => ['Digest blabla']
          },
          request.headers
        )
      end

      def test_construct_redirect_auth
        request = Sapi.create_from_server_array(
          'PATH_INFO'                => '/foo',
          'REQUEST_METHOD'              => 'GET',
          'REDIRECT_HTTP_AUTHORIZATION' => 'Basic bla'
        )

        assert_equal('GET', request.method)
        assert_equal('/foo', request.url)
        assert_equal(
          {
            'Authorization' => ['Basic bla']
          },
          request.headers
        )
      end

      def test_send
        response = Response.new(204, 'Content-Type' => 'text/xml;charset=UTF-8')

        # Second Content-Type header. Normally this doesn't make sense.
        response.add_header('Content-Type', 'application/xml')
        response.body = 'foo'

        (_status, headers, body) = Sapi.send_response(response)

        assert_equal(
          {
            'Content-Type' => "text/xml;charset=UTF-8\napplication/xml"
          },
          headers
        )

        assert_equal('foo', body.read)
      end

      def test_send_limited_by_content_length_string
        response = Response.new(200)

        response.add_header('Content-Length', 19)
        response.body = 'Send this sentence. Ignore this one.'

        (_status, _headers, body) = Sapi.send_response(response)

        assert_equal('Send this sentence.', body.read)
      end

      def test_send_limited_by_content_length_stream
        response = Response.new(200, 'Content-Length' => 19)

        body = StringIO.new
        body.write('Ignore this. Send this sentence. Ignore this too.')
        body.rewind
        body.read(13)
        response.body = body

        (_status, _headers, body) = Sapi.send_response(response)

        assert_equal('Send this sentence.', body.read)
      end
    end
  end
end
