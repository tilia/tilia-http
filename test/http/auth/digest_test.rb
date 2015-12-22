require 'digest'
require 'test_helper'

module Tilia
  module Http
    class DigestTest < Minitest::Test
      REALM = 'SabreDAV unittest'

      def setup
        @response = Response.new
        @request = Request.new
        @auth = Auth::Digest.new(REALM, @request, @response)
      end

      def uniqid
        Digest::SHA1.hexdigest((Time.now.to_f + rand).to_s)[0..14]
      end

      def get_server_tokens(qop = Auth::Digest::QOP_AUTH)
        @auth.require_login

        case qop
        when Auth::Digest::QOP_AUTH
          qopstr = 'auth'
        when Auth::Digest::QOP_AUTHINT
          qopstr = 'auth-int'
        else
          qopstr = 'auth,auth-int'
        end

        test_result = @response.header('WWW-Authenticate') =~ /Digest realm="#{REALM}",qop="#{qopstr}",nonce="([0-9a-f]*)",opaque="([0-9a-f]*)"/

        assert(test_result, "The WWW-Authenticate response didn't match our pattern. We received: #{@response.header('WWW-Authenticate')}")

        nonce = Regexp.last_match[1]
        opaque = Regexp.last_match[2]

        # Reset our environment
        setup
        @auth.qop = qop

        [nonce, opaque]
      end

      def test_digest
        (nonce, opaque) = get_server_tokens

        username = 'admin'
        password = '12345'
        nc = '00002'
        cnonce = uniqid

        digest_hash = Digest::MD5.hexdigest(
          "#{Digest::MD5.hexdigest("#{username}:#{REALM}:#{password}")}:#{nonce}:#{nc}:#{cnonce}:auth:#{Digest::MD5.hexdigest('GET:/')}"
        )

        @request.method = 'GET'
        @request.update_header('Authorization', "Digest username=\"#{username}\", realm=\"#{REALM}\", nonce=\"#{nonce}\", uri=\"/\", response=\"#{digest_hash}\", opaque=\"#{opaque}\", qop=auth,nc=#{nc},cnonce=\"#{cnonce}\"")

        @auth.init

        assert_equal(username, @auth.username)
        assert_equal(REALM, @auth.realm)
        assert(@auth.validate_a1(Digest::MD5.hexdigest("#{username}:#{REALM}:#{password}")), 'Authentication is deemed invalid through validateA1')
        assert(@auth.validate_password(password), 'Authentication is deemed invalid through validatepassword')
      end

      def test_invalid_digest
        (nonce, opaque) = get_server_tokens

        username = 'admin'
        password = '12345'
        nc = '00002'
        cnonce = uniqid

        digest_hash = Digest::MD5.hexdigest(
          "#{Digest::MD5.hexdigest("#{username}:#{REALM}:#{password}")}:#{nonce}:#{nc}:#{cnonce}:auth:#{Digest::MD5.hexdigest('GET:/')}"
        )

        @request.method = 'GET'
        @request.update_header('Authorization', "Digest username=\"#{username}\", realm=\"#{REALM}\", nonce=\"#{nonce}\", uri=\"/\", response=\"#{digest_hash}\", opaque=\"#{opaque}\", qop=auth,nc=#{nc},cnonce=\"#{cnonce}\"")

        @auth.init

        refute(@auth.validate_a1(Digest::MD5.hexdigest("#{username}:#{REALM}:#{password}randomness")), 'Authentication is deemed invalid through validateA1')
      end

      def test_invalid_digest2
        @request.method = 'GET'
        @request.update_header('Authorization', 'basic blablabla')

        @auth.init
        refute(@auth.validate_a1(Digest::MD5.hexdigest('user:realm:password')))
      end

      def test_digest_auth_int
        @auth.qop = Auth::Digest::QOP_AUTHINT
        (nonce, opaque) = get_server_tokens(Auth::Digest::QOP_AUTHINT)

        username = 'admin'
        password = '12345'
        nc = '00003'
        cnonce = uniqid

        digest_hash = Digest::MD5.hexdigest(
          "#{Digest::MD5.hexdigest("#{username}:#{REALM}:#{password}")}:#{nonce}:#{nc}:#{cnonce}:auth-int:#{Digest::MD5.hexdigest('POST:/:' + Digest::MD5.hexdigest('body'))}"
        )

        @request.method = 'POST'
        @request.update_header('Authorization', "Digest username=\"#{username}\", realm=\"#{REALM}\", nonce=\"#{nonce}\", uri=\"/\", response=\"#{digest_hash}\", opaque=\"#{opaque}\", qop=auth-int,nc=#{nc},cnonce=\"#{cnonce}\"")
        @request.body = 'body'

        @auth.init

        assert(@auth.validate_a1(Digest::MD5.hexdigest("#{username}:#{REALM}:#{password}")), 'Authentication is deemed invalid through validateA1')
      end

      def test_digest_auth_both
        @auth.qop = Auth::Digest::QOP_AUTHINT | Auth::Digest::QOP_AUTH
        (nonce, opaque) = get_server_tokens(Auth::Digest::QOP_AUTHINT | Auth::Digest::QOP_AUTH)

        username = 'admin'
        password = '12345'
        nc = '00003'
        cnonce = uniqid

        digest_hash = Digest::MD5.hexdigest(
          "#{Digest::MD5.hexdigest("#{username}:#{REALM}:#{password}")}:#{nonce}:#{nc}:#{cnonce}:auth-int:#{Digest::MD5.hexdigest('POST:/:' + Digest::MD5.hexdigest('body'))}"
        )

        @request.method = 'POST'
        @request.update_header('Authorization', "Digest username=\"#{username}\", realm=\"#{REALM}\", nonce=\"#{nonce}\", uri=\"/\", response=\"#{digest_hash}\", opaque=\"#{opaque}\", qop=auth-int,nc=#{nc},cnonce=\"#{cnonce}\"")
        @request.body = 'body'

        @auth.init

        assert(@auth.validate_a1(Digest::MD5.hexdigest("#{username}:#{REALM}:#{password}")), 'Authentication is deemed invalid through validateA1')
      end
    end
  end
end
