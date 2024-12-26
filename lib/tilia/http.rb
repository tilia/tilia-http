require 'uri'
require 'date'

# Namespace for Tilia library
module Tilia
  # Load active support core extensions
  require 'active_support'
  require 'active_support/core_ext'

  # Char detecting functions
  require 'rchardet'

  # Rack for IO handling with server
  require 'rack'

  # HTTP handling
  require 'typhoeus'

  # Tilia libraries
  require 'tilia/event'
  require 'tilia/uri'

  # Namespace of the Tilia::Xml library
  # A collection of useful helpers for parsing or generating various HTTP
  # headers.
  module Http
    require 'tilia/http/auth'
    require 'tilia/http/http_exception'
    require 'tilia/http/client_exception'
    require 'tilia/http/client_http_exception'
    require 'tilia/http/client'
    require 'tilia/http/message_decorator_trait'
    require 'tilia/http/message_interface'
    require 'tilia/http/message'
    require 'tilia/http/request_interface'
    require 'tilia/http/request_decorator'
    require 'tilia/http/request'
    require 'tilia/http/response_interface'
    require 'tilia/http/response_decorator'
    require 'tilia/http/response'
    require 'tilia/http/sapi'
    require 'tilia/http/url_util'
    require 'tilia/http/util'
    require 'tilia/http/version'

    # Parses a HTTP date-string.
    #
    # This method returns false if the date is invalid.
    #
    # The following formats are supported:
    #    Sun, 06 Nov 1994 08:49:37 GMT    ; IMF-fixdate
    #    Sunday, 06-Nov-94 08:49:37 GMT   ; obsolete RFC 850 format
    #    Sun Nov  6 08:49:37 1994         ; ANSI C's asctime format
    #
    # See:
    #   http://tools.ietf.org/html/rfc7231#section-7.1.1.1
    #
    # @param [String] date_string
    # @return [Time, nil]
    def self.parse_date(date_string)
      return nil if date_string.blank?

      # Only the format is checked, valid ranges are checked by strtotime below
      month = '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'
      weekday = '(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)'
      wkday = '(Mon|Tue|Wed|Thu|Fri|Sat|Sun)'
      time = '([0-1]\d|2[0-3])(\:[0-5]\d){2}'
      date3 = month + ' ([12]\d|3[01]| [1-9])'
      date2 = '(0[1-9]|[12]\d|3[01])\-' + month + '\-\d{2}'
      # 4-digit year cannot begin with 0 - unix timestamp begins in 1970
      date1 = '(0[1-9]|[12]\d|3[01]) ' + month + ' [1-9]\d{3}'

      # ANSI C's asctime() format
      # 4-digit year cannot begin with 0 - unix timestamp begins in 1970
      asctime_date = wkday + ' ' + date3 + ' ' + time + ' [1-9]\d{3}'
      # RFC 850, obsoleted by RFC 1036
      rfc850_date = weekday + ', ' + date2 + ' ' + time + ' GMT'
      # RFC 822, updated by RFC 1123
      rfc1123_date = wkday + ', ' + date1 + ' ' + time + ' GMT'
      # allowed date formats by RFC 2616
      http_date = "(#{rfc1123_date}|#{rfc850_date}|#{asctime_date})"

      # allow for space around the string and strip it
      date_string.strip!

      return nil unless date_string =~ /^#{http_date}$/

      date = Time.zone.parse date_string

      # Ruby does not accept ANSI + GMT
      date += date.utc_offset.seconds unless date_string.index('GMT')

      # Correct 2 digit years
      if date.year < 100
        date_string.gsub!(
          format('-%02i', date.year),
          format('-%04i', Time.now.year.div(100) * 100 + date.year)
        )
        date = Time.zone.parse(date_string)
        if date > (Time.now + 1.month)
          date = Time.zone.parse(
            date.to_s.gsub(
              format('%04i', date.year),
              format('%04i', date.year - 100)
            )
          )
        end
      end

      date
    end

    # Transforms a DateTime object to a valid HTTP/1.1 Date header value
    #
    # @param [Time] date_time
    # @return [String]
    def self.to_date(date_time)
      # We need to clone it, as we don't want to affect the existing
      # DateTime.
      date_time.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')
    end

    # This function can be used to aid with content negotiation.
    #
    # It takes 2 arguments, the accept_header_value, which usually comes from
    # an Accept header, and available_options, which contains an array of
    # items that the server can support.
    #
    # The result of this function will be the 'best possible option'. If no
    # best possible option could be found, null is returned.
    #
    # When it's null you can according to the spec either return a default, or
    # you can choose to emit 406 Not Acceptable.
    #
    # The method also accepts sending 'null' for the accept_header_value,
    # implying that no accept header was sent.
    #
    # @param [String, nil] accept_header_value
    # @param [Array<String>] available_options
    # @return [String, nil]
    def self.negotiate_content_type(accept_header_value, available_options)
      if accept_header_value.blank?
        # Grabbing the first in the list.
        return available_options[0]
      end

      proposals = accept_header_value.split(',').map { |m| parse_mime_type(m) }

      options = available_options.map { |m| parse_mime_type(m) }

      last_quality = 0
      last_specificity = 0
      last_option_index = 0
      last_choice = nil

      proposals.each do |proposal|
        # Ignoring broken values.
        next if proposal.nil?

        # If the quality is lower we don't have to bother comparing.
        next if proposal['quality'] < last_quality

        options.each_with_index do |option, option_index|
          if proposal['type'] != '*' && proposal['type'] != option['type']
            # no match on type.
            next
          end
          if proposal['subType'] != '*' && proposal['subType'] != option['subType']
            # no match on subtype.
            next
          end

          # Any parameters appearing on the options must appear on
          # proposals.
          flow = true
          option['parameters'].each do |param_name, param_value|
            flow = false unless proposal['parameters'].key?(param_name)
            flow = false unless param_value == proposal['parameters'][param_name]
          end
          next unless flow

          # If we got here, we have a match on parameters, type and
          # subtype. We need to calculate a score for how specific the
          # match was.
          specificity = (proposal['type'] != '*' ? 20 : 0) +
                        (proposal['subType'] != '*' ? 10 : 0) +
                        (option['parameters'].size)

          # Does this entry win?
          next unless (proposal['quality'] > last_quality) ||
                      (proposal['quality'] == last_quality && specificity > last_specificity) ||
                      (proposal['quality'] == last_quality && specificity == last_specificity && option_index < last_option_index)

          last_quality = proposal['quality']
          last_specificity = specificity
          last_option_index = option_index
          last_choice = available_options[option_index]
        end
      end
      last_choice
    end

    # Parses the Prefer header, as defined in RFC7240.
    #
    # Input can be given as a single header value (string) or multiple headers
    # (array of string).
    #
    # This method will return a key.value array with the various Prefer
    # parameters.
    #
    # Prefer: return=minimal will result in:
    #
    # [ 'return' => 'minimal' ]
    #
    # Prefer: foo, wait=10 will result in:
    #
    # [ 'foo' => true, 'wait' => '10']
    #
    # This method also supports the formats from older drafts of RFC7240, and
    # it will automatically map them to the new values, as the older values
    # are still pretty common.
    #
    # Parameters are currently discarded. There's no known prefer value that
    # uses them.
    #
    # @param [String, Array<String>] input
    # @return array
    def self.parse_prefer(input)
      token = '[!#$%&\'*+\-.^_`~A-Za-z0-9]+'

      # Work in progress
      word = '(?: [a-zA-Z0-9]+ | "[a-zA-Z0-9]*" )'

      pattern = /
^
(?<name> #{token})      # Prefer property name
\s*                     # Optional space
(?: = \s*               # Prefer property value
  (?<value> #{word})
)?
(?: \s* ; (?: .*))?     # Prefer parameters (ignored)
$
/x

      output = {}
      header_values(input).each do |value|
        match = pattern.match(value)
        next unless match

        # Mapping old values to their new counterparts
        case match['name']
        when 'return-asynch'
          output['respond-async'] = true
        when 'return-representation'
          output['return'] = 'representation'
        when 'return-minimal'
          output['return'] = 'minimal'
        when 'strict'
          output['handling'] = 'strict'
        when 'lenient'
          output['handling'] = 'lenient'
        else
          if match['value']
            value = match['value'].gsub(/^"*|"*$/, '')
          else
            value = true
          end

          output[match['name'].downcase] = value.blank? ? true : value
        end
      end
      output
    end

    # This method splits up headers into all their individual values.
    #
    # A HTTP header may have more than one header, such as this:
    #   Cache-Control: private, no-store
    #
    # Header values are always split with a comma.
    #
    # You can pass either a string, or an array. The resulting value is always
    # an array with each spliced value.
    #
    # If the second headers argument is set, this value will simply be merged
    # in. This makes it quicker to merge an old list of values with a new set.
    #
    # @param [String, Array<String>] values
    # @param [String, Array<String>] values2
    # @return [Array<String>]
    def self.header_values(values, values2 = nil)
      values = [values] unless values.is_a?(Array)
      if values2
        values2 = [values2] unless values2.is_a?(Array)
        values.concat(values2)
      end

      result = []
      values.each do |l1|
        l1.split(',').each do |l2|
          result << l2.strip
        end
      end

      result
    end

    # Parses a mime-type and splits it into:
    #
    # 1. type
    # 2. subtype
    # 3. quality
    # 4. parameters
    #
    # @param [String] str
    # @return [Hash, nil]
    def self.parse_mime_type(str)
      parameters = {}
      # If no q= parameter appears, then quality = 1.
      quality = 1

      parts = str.split(';')

      # The first part is the mime-type.
      mime_type = parts.shift

      mime_type = mime_type.strip.split('/')
      if mime_type.size != 2
        # Illegal value
        return nil
      end
      (type, sub_type) = mime_type

      parts.each do |part|
        part = part.strip
        equal = part.index('=')
        if !equal.nil? && equal > 0
          (part_name, part_value) = part.split('=', 2)
        else
          part_name = part
          part_value = nil
        end

        # The quality parameter, if it appears, also marks the end of
        # the parameter list. Anything after the q= counts as an
        # 'accept extension' and could introduce new semantics in
        # content-negotation.
        if part_name != 'q'
          parameters[part_name] = part
        else
          quality = part_value.to_f
          break; # Stop parsing parts
        end
      end

      {
        'type'       => type,
        'subType'    => sub_type,
        'quality'    => quality,
        'parameters' => parameters
      }
    end

    # Encodes the path of a url.
    #
    # slashes (/) are treated as path-separators.
    #
    # @param [String] path
    # @return [String]
    def self.encode_path(path)
      path.gsub(%r{([^A-Za-z0-9_\-\.~\(\)\/:@])}) do |m|
        m.bytes.inject('') do |str, byte|
          str << "%#{format('%02x', byte.ord)}"
        end
      end
    end

    # Encodes a 1 segment of a path
    #
    # Slashes are considered part of the name, and are encoded as %2f
    #
    # @param [String] path_segment
    # @return [String]
    def self.encode_path_segment(path_segment)
      path_segment.gsub(/([^A-Za-z0-9_\-\.~\(\):@])/) do |m|
        m.bytes.inject('') do |str, byte|
          str << "%#{format('%02x', byte.ord)}"
        end
      end
    end

    # Decodes a url-encoded path
    #
    # @param [String] path
    # @return [String]
    def self.decode_path(path)
      decode_path_segment(path)
    end

    # Decodes a url-encoded path segment
    #
    # @param [String] path
    # @return [String]
    def self.decode_path_segment(path)
      path = URI::DEFAULT_PARSER.unescape(path)
      cd = CharDet.detect(path)

      # Best solution I could find ...
      if cd['encoding'] =~ /(?:windows|iso)/i
        path = path.encode('UTF-8', cd['encoding'])
      end

      path
    end
  end
end
