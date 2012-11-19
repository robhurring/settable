module Settable
  module Environment
    module Env
      def self.matches?(environment)
        ::ENV.has_key?(environment.to_s)
      end
    end
  end
end