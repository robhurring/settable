$:.push File.expand_path("../../lib", __FILE__)
require 'test/unit'
require 'settable'

module Rails
 class << self; attr_accessor :env; end
end

class Configuration
  include Settable
  def initialize(&block)
    instance_eval(&block) if block_given?
  end
end

class RailsConfiguration < Configuration
  include Settable::Rails
end

# test using an instance eval'd config
class SettableBlockTest < Test::Unit::TestCase
  def setup
    @config = Configuration.new do
      set :string, 'hello world'
      set :numeric, 10
      set :block do
        'block'
      end
      set :combined, "#{string}-combined"
      enable :tracking
      disable :caching
    end
  end
  
  def test_strings
    assert_equal 'hello world', @config.string
  end
  
  def test_numeric
    assert_equal 10, @config.numeric
  end
  
  def test_block
    assert_equal 'block', @config.block
  end
  
  def test_string_interpolation
    assert_equal 'hello world-combined', @config.combined
  end
  
  def test_enable
    assert @config.tracking
  end
  
  def test_disable
    assert !@config.caching
  end
end

# test individual setting config
class SettableExternalTest < Test::Unit::TestCase
  def setup
    @config = Configuration.new
  end
  
  def test_strings
    @config.set :string, 'hello world'
    assert_equal 'hello world', @config.string
  end
  
  def test_numeric
    @config.set :numeric, 10
    assert_equal 10, @config.numeric
  end
  
  def test_block
    @config.set :block do
      'block'
    end
    assert_equal 'block', @config.block
  end
  
  def test_enable
    @config.enable :tracking
    assert @config.tracking
  end
  
  def test_disable
    @config.disable :caching
    assert !@config.caching
  end
  
  def test_block_with_value
    @config.set :value, 'value'
    @config.set :block do
      value
    end
    assert_equal 'value', @config.block
  end
  
  def test_string_interpolation
    @config.set :hello, 'hello'
    @config.set :combined, "#{@config.hello}-world"
    assert_equal 'hello-world', @config.combined
  end
end

class SettableRailsTest < Test::Unit::TestCase
  def setup
    Rails.env = :development
    @config = RailsConfiguration.new do
      define_environments :custom
      set :debug, in_development?
      
      set :api_token do
        in_production{ return 'PROD' }
        in_custom{ return 'CUSTOM' }
        'DEFAULT'
      end
      
      set :api_endpoint do
        in_environments(:development, :test){ return 'dev.example.com' }
        'example.com'
      end
    end
  end
  
  def test_in_environment_helper
    Rails.env = :development
    assert @config.in_development? == true
  end
  
  def test_custom_environments
    Rails.env = :custom
    assert @config.in_custom? == true
  end
  
  def test_development_block
    Rails.env = :development
    assert_equal 'DEFAULT', @config.api_token
  end

  def test_production_block
    Rails.env = :production
    assert_equal 'PROD', @config.api_token
  end

  def test_custom_block
    Rails.env = :custom
    assert_equal 'CUSTOM', @config.api_token
  end
  
  def test_multiple_environments_in_development
    Rails.env = :development
    assert_equal 'dev.example.com', @config.api_endpoint
  end

  def test_multiple_environments_in_test
    Rails.env = :test
    assert_equal 'dev.example.com', @config.api_endpoint
  end

  def test_multiple_environments_in_other
    Rails.env = :production
    assert_equal 'example.com', @config.api_endpoint
  end
end
