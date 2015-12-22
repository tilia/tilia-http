require 'test_helper'

module Tilia
  module Http
    class URLUtilTest < Minitest::Test
      def resolve_data
        [
          [
            'http://example.org/foo/baz',
            '/bar',
            'http://example.org/bar'
          ],
          [
            'https://example.org/foo',
            '//example.net/',
            'https://example.net/'
          ],
          [
            'https://example.org/foo',
            '?a=b',
            'https://example.org/foo?a=b'
          ],
          [
            '//example.org/foo',
            '?a=b',
            '//example.org/foo?a=b'
          ],
          # Ports and fragments
          [
            'https://example.org:81/foo#hey',
            '?a=b#c=d',
            'https://example.org:81/foo?a=b#c=d'
          ],
          # Relative.. in-directory paths
          [
            'http://example.org/foo/bar',
            'bar2',
            'http://example.org/foo/bar2'
          ],
          # Now the base path ended with a slash
          [
            'http://example.org/foo/bar/',
            'bar2/bar3',
            'http://example.org/foo/bar/bar2/bar3'
          ]
        ]
      end

      def test_encode_path
        str = ''
        (0...128).each do |i|
          str << i.chr
        end

        new_str = UrlUtil.encode_path(str)

        assert_equal(
          '%00%01%02%03%04%05%06%07%08%09%0a%0b%0c%0d%0e%0f' \
          '%10%11%12%13%14%15%16%17%18%19%1a%1b%1c%1d%1e%1f' \
          '%20%21%22%23%24%25%26%27()%2a%2b%2c-./' \
          '0123456789:%3b%3c%3d%3e%3f' \
          '@ABCDEFGHIJKLMNO' \
          'PQRSTUVWXYZ%5b%5c%5d%5e_' \
          '%60abcdefghijklmno' \
          'pqrstuvwxyz%7b%7c%7d~%7f',
          new_str
        )

        assert_equal(str, UrlUtil.decode_path(new_str))
      end

      def test_encode_path_segment
        str = ''
        (0...128).each do |i|
          str << i.chr
        end

        new_str = UrlUtil.encode_path_segment(str)

        assert_equal(
          '%00%01%02%03%04%05%06%07%08%09%0a%0b%0c%0d%0e%0f' \
          '%10%11%12%13%14%15%16%17%18%19%1a%1b%1c%1d%1e%1f' \
          '%20%21%22%23%24%25%26%27()%2a%2b%2c-.%2f' \
          '0123456789:%3b%3c%3d%3e%3f' \
          '@ABCDEFGHIJKLMNO' \
          'PQRSTUVWXYZ%5b%5c%5d%5e_' \
          '%60abcdefghijklmno' \
          'pqrstuvwxyz%7b%7c%7d~%7f',
          new_str
        )

        assert_equal(str, UrlUtil.decode_path_segment(new_str))
      end

      def test_decode
        str = 'Hello%20Test+Test2.txt'
        new_str = UrlUtil.decode_path(str)
        assert_equal('Hello Test+Test2.txt', new_str)
      end

      def test_decode_umlaut
        str = 'Hello%C3%BC.txt'
        new_str = UrlUtil.decode_path(str)
        assert_equal("Hello\xC3\xBC.txt", new_str)
      end

      def test_decode_umlaut_latin1
        str = 'Hello%FC.txt'
        new_str = UrlUtil.decode_path(str)
        assert_equal("Hello\xC3\xBC.txt", new_str)
      end

      def test_decode_accents_windows7
        str = '/webdav/%C3%A0fo%C3%B3'
        new_str = UrlUtil.decode_path(str)
        assert_equal(str.downcase, UrlUtil.encode_path(new_str))
      end

      def test_split_path
        strings = {
          # input                    // expected result
          '/foo/bar'                 => ['/foo', 'bar'],
          '/foo/bar/'                => ['/foo', 'bar'],
          'foo/bar/'                 => ['foo', 'bar'],
          'foo/bar'                  => ['foo', 'bar'],
          'foo/bar/baz'              => ['foo/bar', 'baz'],
          'foo/bar/baz/'             => ['foo/bar', 'baz'],
          'foo'                      => ['', 'foo'],
          'foo/'                     => ['', 'foo'],
          '/foo/'                    => ['', 'foo'],
          '/foo'                     => ['', 'foo'],
          ''                         => [nil, nil],

          # UTF-8
          "/\xC3\xA0fo\xC3\xB3/bar"  => ["/\xC3\xA0fo\xC3\xB3", 'bar'],
          "/\xC3\xA0foo/b\xC3\xBCr/" => ["/\xC3\xA0foo", "b\xC3\xBCr"],
          "foo/\xC3\xA0\xC3\xBCr"    => ['foo', "\xC3\xA0\xC3\xBCr"]
        }

        strings.each do |input, expected|
          output = UrlUtil.split_path(input)
          assert_equal(expected, output)
        end
      end

      def test_resolve
        resolve_data.each do |data|
          (base, update, expected) = data

          assert_equal(expected, UrlUtil.resolve(base, update))
        end
      end
    end
  end
end
