$:.push File.expand_path("../../lib", __FILE__)
require 'settable'

# stub out our rails
module Rails
  def self.env; :blah end
end

class Configuration
  include Settable
  include Settable::Rails
    
  def initialize(&block)
    instance_eval(&block) if block_given?
  end
end

@config = Configuration.new do
  define_environments :blah, :qa
  
  set :something, in_blah?
  set :debug, in_environments?(:development, :test)
  
  if in_production?
    enable :tracking, :caching
  else
    disable :tracking, :caching
  end
  
  set :api_token do
    in_production { return 'PRODTOKEN' }
    in_development{ return 'DEVTOKEN' }
    'OTHERTOKEN'
  end
  
  set :api_endpoint do
    in_environments(:development, :test){ return "http://sandbox.example.com/api/#{api_token}" }
    "http://example.com/api/#{api_token}"
  end
end

# external stuffs
puts @config.inspect

puts '-' * 80

puts @config.tracking?
puts @config.caching?
puts @config.api_token
puts @config.api_endpoint
puts @config.debug?