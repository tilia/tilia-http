require 'test_helper'

module Tilia
  module Http
    class BearerTest < Minitest::Test
      def test_get_token
        request = Request.new(
          'GET',
          '/',
          'Authorization' => 'Bearer 12345'
        )

        bearer = Auth::Bearer.new('Dagger', request, Response.new)

        assert_equal('12345', bearer.token)
      end

      def test_get_credentials_noheader
        request = Request.new('GET', '/', {})
        bearer = Auth::Bearer.new('Dagger', request, Response.new)

        assert_nil(bearer.token)
      end

      def test_get_credentials_not_bearer
        request = Request.new(
          'GET',
          '/',
          'Authorization' => 'QBearer 12345'
        )
        bearer = Auth::Bearer.new('Dagger', request, Response.new)

        assert_nil(bearer.token)
      end

      def test_require_login
        response = Response.new
        bearer = Auth::Bearer.new('Dagger', Request.new, response)

        bearer.require_login

        assert_equal('Bearer realm="Dagger"', response.header('WWW-Authenticate'))
        assert_equal(401, response.status)
      end
    end
  end
end
