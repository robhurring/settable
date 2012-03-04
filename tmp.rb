require './lib/settable'
require 'pp'

module Rails
 class << self; attr_accessor :env; end
 self.env = :development
end

class Configuration
  include Settable

  def initialize(&block)
    instance_eval &block
  end
end

$app_config = Configuration.new do
  set :key, 'value'
end

$seo_config = Configuration.new do
  enable :tracking
end

pp $seo_config.tracking?

class RailsConfiguration
  include Settable
  include Settable::Rails
  make_settable

  enable :logging
  set :error_reporting, in_production?

  namespace :seo do
    set :tracking, in_environments?(:production, :certification)
  end

  namespace :api do
    set :token do
      in_production{ return 'prodtoken' }
      'devtoken'
    end
  end
end
