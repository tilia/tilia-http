require 'test_helper'
require 'stringio'
require 'http/client_mock'

module Tilia
  module Http
    class ClientTest < Minitest::Test
      # it 'testCreateCurlSettingsArrayGET' do
      #   client = ClientMock.new
      #   client.add_curl_setting(Curl::CURLOPT_POSTREDIR, 0)
      #
      #   request = Request.new('GET', 'http://example.org/', { 'X-Foo' => 'bar' })
      #
      #   settings = {
      #     Curl::CURLOPT_HEADER         => true,
      #     Curl::CURLOPT_POSTREDIR      => 0,
      #     :CURLOPT_HTTPHEADER     => ['X-Foo: bar'],
      #     Curl::CURLOPT_NOBODY         => false,
      #     Curl::CURLOPT_URL            => 'http://example.org/',
      #     Curl::CURLOPT_CUSTOMREQUEST  => 'GET',
      #     Curl::CURLOPT_POSTFIELDS     => '',
      #     :CURLOPT_PUT            => false
      #   }
      #
      #   assert_equal(settings, client.create_curl_settings_array(request))
      # end
      #
      # it 'testCreateCurlSettingsArrayHEAD' do
      #   client = ClientMock.new
      #   request = Request.new('HEAD', 'http://example.org/', {'X-Foo' => 'bar'})
      #
      #   settings = {
      #     Curl::CURLOPT_HEADER         => true,
      #     Curl::CURLOPT_NOBODY         => true,
      #     Curl::CURLOPT_CUSTOMREQUEST  => 'HEAD',
      #     :CURLOPT_HTTPHEADER     => ['X-Foo: bar'],
      #     Curl::CURLOPT_URL            => 'http://example.org/',
      #     Curl::CURLOPT_POSTFIELDS     => '',
      #     :CURLOPT_PUT            => false
      #   }
      #
      #   assert_equal(settings, client.create_curl_settings_array(request))
      # end
      #
      # it 'testCreateCurlSettingsArrayGETAfterHEAD' do
      #   client = ClientMock.new
      #   request = Request.new('HEAD', 'http://example.org/', {'X-Foo' => 'bar'})
      #
      #   # Parsing the settings for this method, and discarding the result.
      #   # This will cause the client to automatically persist previous
      #   # settings and will help us detect problems.
      #   client.create_curl_settings_array(request)
      #
      #   # This is the real request.
      #   request = Request.new('GET', 'http://example.org/', {'X-Foo' => 'bar'})
      #
      #   settings = {
      #     Curl::CURLOPT_CUSTOMREQUEST  => 'GET',
      #     Curl::CURLOPT_HEADER         => true,
      #     :CURLOPT_HTTPHEADER     => ['X-Foo: bar'],
      #     Curl::CURLOPT_NOBODY         => false,
      #     Curl::CURLOPT_URL            => 'http://example.org/',
      #     Curl::CURLOPT_POSTFIELDS     => '',
      #     :CURLOPT_PUT            => false
      #   }
      #
      #   assert_equal(settings, client.create_curl_settings_array(request))
      # end
      #
      # it 'testCreateCurlSettingsArrayPUTStream' do
      #   pending
      #   client = ClientMock.new
      #
      #   h = StringIO.new
      #   h.write('booh')
      #   request = Request.new('PUT', 'http://example.org/', {'X-Foo' => 'bar'}, h)
      #
      #   settings = {
      #     Curl::CURLOPT_HEADER         => true,
      #     :CURLOPT_PUT            => true,
      #     :CURLOPT_INFILE         => h,
      #     Curl::CURLOPT_NOBODY         => false,
      #     Curl::CURLOPT_CUSTOMREQUEST  => 'PUT',
      #     :CURLOPT_HTTPHEADER     => ['X-Foo: bar'],
      #     Curl::CURLOPT_URL            => 'http://example.org/'
      #   }
      #
      #   assert_equal(settings, client.create_curl_settings_array(request))
      # end
      #
      # it 'testCreateCurlSettingsArrayPUTString' do
      #   client = ClientMock.new
      #   request = Request.new('PUT', 'http://example.org/', {'X-Foo' => 'bar'}, 'boo')
      #
      #   settings = {
      #     Curl::CURLOPT_HEADER         => true,
      #     Curl::CURLOPT_NOBODY         => false,
      #     Curl::CURLOPT_POSTFIELDS     => 'boo',
      #     Curl::CURLOPT_CUSTOMREQUEST  => 'PUT',
      #     :CURLOPT_HTTPHEADER     => ['X-Foo: bar'],
      #     Curl::CURLOPT_URL            => 'http://example.org/'
      #   }
      #
      #   assert_equal(settings, client.create_curl_settings_array(request))
      # end

      def test_send
        client = ClientMock.new
        request = Request.new('GET', 'http://example.org/')

        response = nil
        client.on(
          'doRequest',
          lambda do |_|
            response = Response.new(200)
          end
        )

        response = client.send_request(request)

        assert_equal(200, response.status)
      end

      def test_send_client_error
        client = ClientMock.new
        request = Request.new('GET', 'http://example.org/')

        client.on(
          'doRequest',
          lambda do |_|
            fail ClientException, 'aaah'
          end
        )

        called = false
        client.on(
          'exception',
          lambda do |_a, _b, _c, _d|
            called = true
          end
        )

        assert_raises(ClientException) { client.send_request(request) }

        assert(called)
      end

      def test_send_http_error
        client = ClientMock.new
        request = Request.new('GET', 'http://example.org/')

        client.on(
          'doRequest',
          lambda do |args|
            args.response = Response.new(404)
          end
        )

        called = 0
        client.on(
          'error',
          lambda do |_a, _b, _c, _d|
            called += 1
          end
        )
        client.on(
          'error:404',
          lambda do |_a, _b, _c, _d|
            called += 1
          end
        )

        client.send_request(request)
        assert_equal(2, called)
      end

      def test_send_retry
        client = ClientMock.new
        request = Request.new('GET', 'http://example.org/')

        called = 0
        client.on(
          'doRequest',
          lambda do |args|
            called += 1
            if called < 3
              args.response = Response.new(404)
            else
              args.response = Response.new(200)
            end
          end
        )

        error_called = 0
        client.on(
          'error',
          lambda do |_a, _b, do_retry, _d|
            error_called += 1
            do_retry.value = true
          end
        )

        response = client.send_request(request)
        assert_equal(3, called)
        assert_equal(2, error_called)
        assert_equal(200, response.status)
      end

      def test_http_error_exception
        client = ClientMock.new
        client.throw_exceptions = true
        request = Request.new('GET', 'http://example.org/')

        client.on(
          'doRequest',
          lambda do |args|
            args.response = Response.new(404)
          end
        )

        error = assert_raises(Exception) { client.send_request(request) }
        assert_kind_of(ClientHttpException, error)
        assert_equal(404, error.http_status)
        assert_kind_of(Response, error.response)
      end

      # it 'testParseCurlResult' do
      #   client = ClientMock.new
      #   client.on(
      #     'curlStuff',
      #     lambda do |args|
      #       args.return = [
      #         {
      #           'header_size' => 33,
      #           'http_code'   => 200
      #         },
      #         0,
      #         ''
      #       ]
      #     end
      #   )
      #
      #   body = "HTTP/1.1 200 OK\r\nHeader1:Val1\r\n\r\nFoo"
      #   result = client.parse_curl_result(body, 'foobar')
      #
      #   assert_equal(Client::STATUS_SUCCESS, result['status'])
      #   assert_equal(200, result['http_code'])
      #   assert_equal(200, result['response'].status)
      #   assert_equal({ 'Header1' => ['Val1'] }, result['response'].headers)
      #   assert_equal('Foo', result['response'].body_as_string)
      # end
      #
      # it 'testParseCurlError' do
      #   client = ClientMock.new
      #   client.on(
      #     'curlStuff',
      #     lambda do |args|
      #       args.return = [
      #         { },
      #         1,
      #         'Curl error'
      #       ]
      #     end
      #   )
      #
      #   body = "HTTP/1.1 200 OK\r\nHeader1:Val1\r\n\r\nFoo"
      #   result = client.parse_curl_result(body, 'foobar')
      #
      #   assert_equal(Client::STATUS_CURLERROR, result['status'])
      #   assert_equal(1, result['curl_errno'])
      #   assert_equal('Curl error', result['curl_errmsg'])
      # end
      #
      # it 'testDoRequest' do
      #   client = ClientMock.new
      #   request = Request.new('GET', 'http://example.org/')
      #   client.on(
      #     'curlExec',
      #     lambda do |args|
      #       args.curl_handle = "HTTP/1.1 200 OK\r\nHeader1:Val1\r\n\r\nFoo"
      #     end
      #   )
      #
      #   client.on(
      #     'curlStuff',
      #     lambda do |args|
      #       args.return = [
      #         {
      #           'header_size' => 33,
      #             'http_code'   => 200
      #         },
      #         0,
      #         ''
      #       ]
      #     end
      #   )
      #   response = client.do_request(request)
      #   assert_equal(200, response.status)
      #   assert_equal({ 'Header1' => ['Val1'] }, response.headers)
      #   assert_equal('Foo', response.body_as_string)
      # end
      #
      # it 'testDoRequestCurlError' do
      #   client = ClientMock.new
      #   request = Request.new('GET', 'http://example.org/')
      #   client.on(
      #     'curlExec',
      #     lambda do |args|
      #       args.curl_handle = ''
      #     end
      #   )
      #
      #   client.on(
      #     'curlStuff',
      #     lambda do |args|
      #       args.return = [
      #         { },
      #         1,
      #         'Curl error'
      #       ]
      #     end
      #   )
      #
      #   expect { response = client.do_request(request) }.to raise_error ClientException do |error|
      #     assert_equal(1, error.code)
      #     assert_equal('Curl error', error.message)
      #   end
      # end
    end
  end
end
