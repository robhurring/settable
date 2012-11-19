module Settable
  module Environment
    module Rails
      def self.matches?(environment)
        return false unless defined?(::Rails)
        ::Rails.env.to_s == environment.to_s
      end
    end
  end
end