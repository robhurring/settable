$:.push File.expand_path("../../lib", __FILE__)
require 'settable'

class Configuration
  include Settable
  
  def initialize(&block)
    instance_eval(&block) if block_given?
  end
end

config = Configuration.new do
  set :environment, 'development'
  
  set :api_token do
    return 'PRODTOKEN' if environment == 'production'
    'DEVTOKEN'
  end
  
  set :api_endpoint, "http://example.com/api/#{api_token}"
  set :environment, 'production'
end

# external stuffs
config.set :something, 1
config.enable :debug

puts config.inspect

puts '-' * 80

puts config.environment
puts config.api_token
puts config.api_endpoint
puts config.something
puts config.debug?