require 'base64'
require 'test_helper'

module Tilia
  module Http
    class BasicTest < Minitest::Test
      def test_get_credentials
        request = Request.new(
          'GET',
          '/',
          'Authorization' => "Basic #{Base64.strict_encode64('user:pass:bla')}"
        )

        basic = Auth::Basic.new('Dagger', request, Response.new)

        assert_equal(['user', 'pass:bla'], basic.credentials)
      end

      def test_get_invalid_credentials_colon_missing
        request = Request.new(
          'GET',
          '/',
          'Authorization' => "Basic #{Base64.strict_encode64('userpass')}"
        )

        basic = Auth::Basic.new('Dagger', request, Response.new)

        assert_nil(basic.credentials)
      end

      def test_credentials_noheader
        request = Request.new('GET', '/', {})
        basic = Auth::Basic.new('Dagger', request, Response.new)

        assert_nil(basic.credentials)
      end

      def test_credentials_not_basic
        request = Request.new(
          'GET',
          '/',
          'Authorization' => "QBasic #{Base64.strict_encode64('user:pass:bla')}"
        )
        basic = Auth::Basic.new('Dagger', request, Response.new)

        assert_nil(basic.credentials)
      end

      def test_require_login
        response = Response.new
        basic = Auth::Basic.new('Dagger', Request.new, response)

        basic.require_login

        assert_equal('Basic realm="Dagger"', response.header('WWW-Authenticate'))
        assert_equal(401, response.status)
      end
    end
  end
end
