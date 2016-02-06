require 'test_helper'
require 'stringio'

module Tilia
  module Http
    class MessageTest < Minitest::Test
      def test_construct
        message = MessageMock.new
        assert_kind_of(Message, message)
      end

      def test_stream_body
        body = 'foo'
        h = StringIO.new
        h.write(body)
        h.rewind

        message = MessageMock.new
        message.body = h

        assert_equal(body, message.body_as_string)
        h.rewind
        assert_equal(body, message.body_as_stream.read)
        h.rewind
        assert_equal(body, message.body.read)
      end

      def test_string_body
        body = 'foo'

        message = MessageMock.new
        message.body = body

        assert_equal(body, message.body_as_string)
        assert_equal(body, message.body_as_stream.read)
        assert_equal(body, message.body)
      end

      # It's possible that streams contains more data than the Content-Length.
      #
      # The request object should make sure to never emit more than
      # Content-Length, if Content-Length is set.
      #
      # This is in particular useful when respoding to range requests with
      # streams that represent files on the filesystem, as it's possible to just
      # seek the stream to a certain point, set the content-length and let the
      # request object do the rest.
      def test_long_stream_to_string_body
        body = StringIO.new
        body.write('abcdefg')
        body.seek(2)

        message = MessageMock.new
        message.body = body
        message.update_header('Content-Length', '4')

        assert_equal(
          'cdef',
          message.body_as_string
        )
      end

      def test_get_empty_body_stream
        message = MessageMock.new
        body = message.body_as_stream

        assert_equal('', body.read)
      end

      def test_get_empty_body_string
        message = MessageMock.new
        body = message.body_as_string

        assert_equal('', body)
      end

      def test_headers
        message = MessageMock.new
        message.update_header('X-Foo', 'bar')

        # Testing caselessness
        assert_equal('bar', message.header('X-Foo'))
        assert_equal('bar', message.header('x-fOO'))

        assert(message.remove_header('X-FOO'))
        assert_nil(message.header('X-Foo'))
        refute(message.remove_header('X-FOO'))
      end

      def test_set_headers
        message = MessageMock.new

        headers = {
          'X-Foo' => ['1'],
          'X-Bar' => ['2']
        }

        message.update_headers(headers)
        assert_equal(headers, message.headers)

        message.update_headers(
          'X-Foo' => ['3', '4'],
          'X-Bar' => '5'
        )

        expected = {
          'X-Foo' => ['3', '4'],
          'X-Bar' => ['5']
        }

        assert_equal(expected, message.headers)
      end

      def test_add_headers
        message = MessageMock.new

        headers = {
          'X-Foo' => ['1'],
          'X-Bar' => ['2']
        }

        message.add_headers(headers)
        assert_equal(headers, message.headers)

        message.add_headers(
          'X-Foo' => ['3', '4'],
          'X-Bar' => '5'
        )

        expected = {
          'X-Foo' => ['1', '3', '4'],
          'X-Bar' => ['2', '5']
        }

        assert_equal(expected, message.headers)
      end

      def test_send_body
        message = MessageMock.new

        # String
        message.body = 'foo'

        # Stream
        h = StringIO.new
        h.write('bar')
        h.rewind
        message.body = h

        body = message.body
        body.rewind

        assert_equal('bar', body.read)
      end

      def test_multiple_headers
        message = MessageMock.new
        message.update_header('a', '1')
        message.add_header('A', '2')

        assert_equal('1,2', message.header('A'))
        assert_equal('1,2', message.header('a'))

        assert_equal(['1', '2'], message.header_as_array('A'))
        assert_equal(['1', '2'], message.header_as_array('a'))

        assert_equal([], message.header_as_array('B'))
      end

      def test_has_headers
        message = MessageMock.new

        refute(message.header?('X-Foo'))
        message.update_header('X-Foo', 'Bar')
        assert(message.header?('X-Foo'))
      end
    end

    class MessageMock
      include Message
    end
  end
end
