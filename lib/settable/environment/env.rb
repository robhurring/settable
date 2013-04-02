module Settable
  module Environment
    module Env
      def self.call(environment)
        ::ENV.has_key?(environment.to_s)
      end
    end
  end
end