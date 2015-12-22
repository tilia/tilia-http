require 'digest'
require 'base64'
require 'openssl'
require 'test_helper'

module Tilia
  module Http
    class AWSTest < Minitest::Test
      REALM = 'SabreDAV unittest'

      def setup
        @response = Response.new
        @request = Request.new
        @auth = Auth::Aws.new(REALM, @request, @response)
      end

      # Generates an HMAC-SHA1 signature
      #
      # @param [String] key
      # @param [String] message
      # @return [String]
      def hmacsha1(key, message)
        # Built in in Ruby
        OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), key, message)
      end

      def test_no_header
        @request.method = 'GET'
        result = @auth.init

        refute(result, 'No AWS Authorization header was supplied, so we should have gotten false')

        assert_equal(Auth::Aws::ERR_NOAWSHEADER, @auth.error_code)
      end

      def test_incorrect_content_md5
        access_key = 'accessKey'
        secret_key = 'secretKey'

        @request.method = 'GET'
        @request.update_headers(
          'Authorization' => "AWS #{access_key}:sig",
          'Content-MD5'   => 'garbage'
        )
        @request.url = '/'

        @auth.init
        result = @auth.validate(secret_key)

        refute(result)
        assert_equal(Auth::Aws::ERR_MD5CHECKSUMWRONG, @auth.error_code)
      end

      def test_no_date
        access_key = 'accessKey'
        secret_key = 'secretKey'
        content = 'thisisthebody'
        content_md5 = Base64.strict_encode64(Digest::MD5.digest(content))

        @request.method = 'POST'
        @request.update_headers(
          'Authorization' => "AWS #{access_key}:sig",
          'Content-MD5'   => content_md5
        )
        @request.body = content

        @auth.init
        result = @auth.validate(secret_key)

        refute(result)
        assert_equal(Auth::Aws::ERR_INVALIDDATEFORMAT, @auth.error_code)
      end

      def test_future_date
        access_key = 'accessKey'
        secret_key = 'secretKey'
        content = 'thisisthebody'
        content_md5 = Base64.strict_encode64(Digest::MD5.digest(content))

        date = Time.zone.now + 20.minutes
        date = date.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

        @request.method = 'POST'
        @request.update_headers(
          'Authorization' => "AWS #{access_key}:sig",
          'Content-MD5'   => content_md5,
          'Date'          => date
        )

        @request.body = content

        @auth.init
        result = @auth.validate(secret_key)

        refute(result)
        assert_equal(Auth::Aws::ERR_REQUESTTIMESKEWED, @auth.error_code)
      end

      def test_past_date
        access_key = 'accessKey'
        secret_key = 'secretKey'
        content = 'thisisthebody'
        content_md5 = Base64.strict_encode64(Digest::MD5.digest(content))

        date = Time.zone.now - 20.minutes
        date = date.to_time.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

        @request.method = 'POST'
        @request.update_headers(
          'Authorization' => "AWS #{access_key}:sig",
          'Content-MD5'   => content_md5,
          'Date'          => date
        )

        @request.body = content

        @auth.init
        result = @auth.validate(secret_key)

        refute(result)
        assert_equal(Auth::Aws::ERR_REQUESTTIMESKEWED, @auth.error_code)
      end

      def test_incorrect_signature
        access_key = 'accessKey'
        secret_key = 'secretKey'
        content = 'thisisthebody'
        content_md5 = Base64.strict_encode64(Digest::MD5.digest(content))

        date = Time.zone.now
        date = date.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

        @request.url = '/'
        @request.method = 'POST'
        @request.update_headers(
          'Authorization' => "AWS #{access_key}:sig",
          'Content-MD5'   => content_md5,
          'X-amz-date'    => date
        )
        @request.body = content

        @auth.init
        result = @auth.validate(secret_key)

        refute(result)
        assert_equal(Auth::Aws::ERR_INVALIDSIGNATURE, @auth.error_code)
      end

      def test_valid_request
        access_key = 'accessKey'
        secret_key = 'secretKey'
        content = 'thisisthebody'
        content_md5 = Base64.strict_encode64(Digest::MD5.digest(content))

        date = Time.zone.now
        date = date.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

        sig = Base64.strict_encode64(
          hmacsha1(
            secret_key,
            "POST\n#{content_md5}\n\n#{date}\nx-amz-date:#{date}\n/evert"
          )
        )

        @request.url = '/evert'
        @request.method = 'POST'
        @request.update_headers(
          'Authorization' => "AWS #{access_key}:#{sig}",
          'Content-MD5'   => content_md5,
          'X-amz-date'    => date
        )

        @request.body = content

        @auth.init
        result = @auth.validate(secret_key)

        assert(result, "Signature did not validate, got errorcode #{@auth.error_code}")
        assert_equal(access_key, @auth.access_key)
      end

      def test401
        @auth.require_login
        header = @response.header('WWW-Authenticate') =~ /^AWS$/
        assert(header, 'The WWW-Authenticate response didn\'t match our pattern')
      end
    end
  end
end
