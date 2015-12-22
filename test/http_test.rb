require 'test_helper'

module Tilia
  module Http
    class FunctionsTest < Minitest::Test
      def header_values_data
        [
          [
            'a',
            ['a']
          ],
          [
            'a,b',
            ['a', 'b']
          ],
          [
            'a, b',
            ['a', 'b']
          ],
          [
            ['a, b'],
            ['a', 'b']
          ],
          [
            ['a, b', 'c', 'd,e'],
            ['a', 'b', 'c', 'd', 'e']
          ]
        ]
      end

      def prefer_data
        [
          [
            'foo; bar',
            { 'foo' => true }
          ],
          [
            'foo; bar=""',
            { 'foo' => true }
          ],
          [
            'foo=""; bar',
            { 'foo' => true }
          ],
          [
            'FOO',
            { 'foo' => true }
          ],
          [
            'respond-async',
            { 'respond-async' => true }
          ],
          [
            ['respond-async, wait=100', 'handling=lenient'],
            { 'respond-async' => true, 'wait' => '100', 'handling' => 'lenient' }
          ],
          [
            ['respond-async, wait=100, handling=lenient'],
            { 'respond-async' => true, 'wait' => '100', 'handling' => 'lenient' }
          ],
          # Old values
          [
            'return-asynch, return-representation',
            { 'respond-async' => true, 'return' => 'representation' }
          ],
          [
            'return-minimal',
            { 'return' => 'minimal' }
          ],
          [

            'strict',
            { 'handling' => 'strict' }
          ],
          [
            'lenient',
            { 'handling' => 'lenient' }
          ],
          # Invalid token
          [
            ['foo=%bar%'],
            {}
          ]
        ]
      end

      def test_get_header_values
        header_values_data.each do |data|
          (input, output) = data
          assert_equal(output, Http.header_values(input))
        end
      end

      def test_prefer
        prefer_data.each do |data|
          (input, output) = data
          assert_equal(output, Http.parse_prefer(input))
        end
      end
    end
  end
end
