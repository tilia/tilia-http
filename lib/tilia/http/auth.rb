module Tilia
  module Http
    # Namespace for Tilia::Http::Auth::* classes
    module Auth
      require 'tilia/http/auth/abstract_auth'
      require 'tilia/http/auth/aws'
      require 'tilia/http/auth/basic'
      require 'tilia/http/auth/bearer'
      require 'tilia/http/auth/digest'
    end
  end
end
