module Tilia
  module Http
    # TODO: document
    class SapiMock < Sapi
      # TODO: document
      def initialize(env = {})
        env = Rack::MockRequest.env_for.merge env
        super(env)
      end
    end
  end
end
