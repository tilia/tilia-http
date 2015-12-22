require 'test_helper'

module Tilia
  module Http
    class UtilTest < Minitest::Test
      def negotiate_data
        [
          [ # simple
            'application/xml',
            ['application/xml'],
            'application/xml'
          ],
          [ # no header
            nil,
            ['application/xml'],
            'application/xml'
          ],
          [ # 2 options
            'application/json',
            ['application/xml', 'application/json'],
            'application/json'
          ],
          [ # 2 choices
            'application/json, application/xml',
            ['application/xml'],
            'application/xml'
          ],
          [ # quality
            'application/xml;q=0.2, application/json',
            ['application/xml', 'application/json'],
            'application/json'
          ],
          [ # wildcard
            'image/jpeg, image/png, */*',
            ['application/xml', 'application/json'],
            'application/xml'
          ],
          [ # wildcard + quality
            'image/jpeg, image/png; q=0.5, */*',
            ['application/xml', 'application/json', 'image/png'],
            'application/xml'
          ],
          [ # no match
            'image/jpeg',
            ['application/xml'],
            nil
          ],
          [ # This is used in sabre/dav
            'text/vcard; version=4.0',
            [
              # Most often used mime-type. Version 3
              'text/x-vcard',
              # The correct standard mime-type. Defaults to version 3 as
              # well.
              'text/vcard',
              # vCard 4
              'text/vcard; version=4.0',
              # vCard 3
              'text/vcard; version=3.0',
              # jCard
              'application/vcard+json'
            ],
            'text/vcard; version=4.0'

          ],
          [ # rfc7231 example 1
            'audio/*; q=0.2, audio/basic',
            [
              'audio/pcm',
              'audio/basic'
            ],
            'audio/basic'
          ],
          [ # Lower quality after
            'audio/pcm; q=0.2, audio/basic; q=0.1',
            [
              'audio/pcm',
              'audio/basic'
            ],
            'audio/pcm'
          ],
          [ # Random parameter, should be ignored
            'audio/pcm; hello; q=0.2, audio/basic; q=0.1',
            [
              'audio/pcm',
              'audio/basic'
            ],
            'audio/pcm'
          ],
          [ # No whitepace after type, should pick the one that is the most specific.
            'text/vcard;version=3.0, text/vcard',
            [
              'text/vcard',
              'text/vcard; version=3.0'
            ],
            'text/vcard; version=3.0'
          ],
          [ # Same as last one, but order is different
            'text/vcard, text/vcard;version=3.0',
            [
              'text/vcard; version=3.0',
              'text/vcard'
            ],
            'text/vcard; version=3.0'
          ],
          [ # Charset should be ignored here.
            'text/vcard; charset=utf-8; version=3.0, text/vcard',
            [
              'text/vcard',
              'text/vcard; version=3.0'
            ],
            'text/vcard; version=3.0'
          ],
          [ # Undefined offset issue.
            'text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2',
            ['application/xml', 'application/json', 'image/png'],
            'application/xml'
          ]
        ]
      end

      def test_parse_http_date
        times = [
          'Wed, 13 Oct 2010 10:26:00 GMT',
          'Wednesday, 13-Oct-10 10:26:00 GMT',
          'Wed Oct 13 10:26:00 2010'
        ]

        expected = 1_286_965_560

        times.each do |time|
          result = Util.parse_http_date(time)
          assert_equal(expected, result.to_i)
        end

        result = Util.parse_http_date('Wed Oct  6 10:26:00 2010')
        assert_equal(1_286_360_760, result.to_i)
      end

      def test_parse_http_date_fail
        times = [
          # random string
          'NOW',
          # not-GMT timezone
          'Wednesday, 13-Oct-10 10:26:00 UTC',
          # No space before the 6
          'Wed Oct 6 10:26:00 2010',
          # Invalid day
          'Wed Oct  0 10:26:00 2010',
          'Wed Oct 32 10:26:00 2010',
          'Wed, 0 Oct 2010 10:26:00 GMT',
          'Wed, 32 Oct 2010 10:26:00 GMT',
          'Wednesday, 32-Oct-10 10:26:00 GMT',
          # Invalid hour
          'Wed, 13 Oct 2010 24:26:00 GMT',
          'Wednesday, 13-Oct-10 24:26:00 GMT',
          'Wed Oct 13 24:26:00 2010'
        ]

        times.each do |time|
          refute(Util.parse_http_date(time))
        end
      end

      def test_timezones
        Time.use_zone('Amsterdam') do
          test_parse_http_date
        end
      end

      def test_to_http_date
        dt = Time.zone.parse('2011-12-10 12:00:00 +0200')

        assert_equal('Sat, 10 Dec 2011 10:00:00 GMT', Util.to_http_date(dt))
      end

      def test_negotiate
        negotiate_data.each do |data|
          (accept_header, available, expected) = data

          assert_equal(expected, Util.negotiate(accept_header, available))
        end
      end
    end
  end
end
