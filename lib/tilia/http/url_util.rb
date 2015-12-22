module Tilia
  module Http
    # URL utility class
    #
    # Note: this class is deprecated. All its functionality moved to functions.php
    # or sabre\uri.
    #
    # @deprectated
    module UrlUtil
      # Encodes the path of a url.
      #
      # slashes (/) are treated as path-separators.
      #
      # @deprecated use \Sabre\HTTP\encode_path
      # @param string path
      # @return string
      def self.encode_path(path)
        Tilia::Http.encode_path(path)
      end

      # Encodes a 1 segment of a path
      #
      # Slashes are considered part of the name, and are encoded as %2f
      #
      # @deprecated use \Sabre\HTTP\encode_path_segment
      # @param string path_segment
      # @return string
      def self.encode_path_segment(path_segment)
        Tilia::Http.encode_path_segment(path_segment)
      end

      # Decodes a url-encoded path
      #
      # @deprecated use \Sabre\HTTP\decodePath
      # @param string path
      # @return string
      def self.decode_path(path)
        Tilia::Http.decode_path(path)
      end

      # Decodes a url-encoded path segment
      #
      # @deprecated use \Sabre\HTTP\decode_path_segment
      # @param string path
      # @return string
      def self.decode_path_segment(path)
        Tilia::Http.decode_path_segment(path)
      end

      # Returns the 'dirname' and 'basename' for a path.
      #
      # @deprecated Use Sabre\Uri\split.
      # @param string path
      # @return array
      def self.split_path(path)
        Tilia::Uri.split(path)
      end

      # Resolves relative urls, like a browser would.
      #
      # @deprecated Use Sabre\Uri\resolve.
      # @param string base_path
      # @param string new_path
      # @return string
      def self.resolve(base_path, new_path)
        Tilia::Uri.resolve(base_path, new_path)
      end
    end
  end
end
