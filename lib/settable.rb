module Settable
  VERSION = "1.0"
  
  module Rails
    DEFAULT_ENVIRONMENTS = [:development, :production, :test]
    CUSTOM_ENVIRONMENTS = []
    
    # allow us to add custom environment helpers
    def define_environments(*envs)
      envs.each do |env|
        CUSTOM_ENVIRONMENTS << env
        define_metaclass_method(:"in_#{env}"){ |&block| in_environment(env.to_sym, &block) }
        define_metaclass_method(:"in_#{env}?"){ in_environment?(env.to_sym) }
      end
    end
    alias_method :define_environment, :define_environments
    
    # create our default environments
    DEFAULT_ENVIRONMENTS.each do |env|
      define_method(:"in_#{env}"){ |&block| in_environment(env.to_sym, &block) }
      define_method(:"in_#{env}?"){ in_environment?(env.to_sym) }      
    end
    
    # helper method that will call the block if the Rails.env matches the given environments
    def in_environments(*envs, &block)
      block.call if envs.include?(::Rails.env.to_sym)
    end
    alias_method :in_environment, :in_environments
    
    # tests if we're in the given environment(s)
    def in_environments?(*envs)
      envs.include?(::Rails.env.to_sym)
    end
    alias_method :in_environment?, :in_environments?
  end
  
  def define_metaclass_method(method, &block)
    (class << self; self; end).send :define_method, method, &block
  end
  
  # list 
  def __settables__
    @__settables__ ||= []
  end
  
  # modified from sinatra
  def set(key, value=nil, &block)
    raise ArgumentError, "You must specify either a block or value" if block_given? && !value.nil?
    value = block if block_given?
    if value.is_a?(Proc)
      __settables__ << key
      define_metaclass_method key, &value
      define_metaclass_method(:"#{key}?"){ !!__send__(key) }
    else
      set key, Proc.new{value}
    end
  end

  def enable(*keys)
    keys.each{ |key| set key, true }
  end
  
  def disable(*keys)
    keys.each{ |key| set key, false }
  end
end