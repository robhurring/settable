About
===

Simple library to make configuration files dead simple. It uses "set, enable, disable" just like capistrano and sinatra. It also has some rails helpers to change settings based off environments.

To create the configuration wrapper, its as simple as:

    class Configuration
      include Settable

      def initialize(&block)
        instance_eval(&block) if block_given?
      end
    end

to use this in your initializer, script, etc. just open it up and use set/enable/etc    

    # using it without the rails helpers
    config = Configuration.new do
      set :environment, 'development'
      enable :debug
      
      set :api_token do
        return 'PRODTOKEN' if environment == 'production'
        'DEVTOKEN'
      end

      set :api_endpoint, "http://example.com/api/#{api_token}"
    end
    
    puts config.debug?
    puts config.api_endpoint
    
or if you wanted to use it with rails    
    
    class Configuration
      include Settable
      include Settable::Rails

      def initialize(&block)
        instance_eval(&block) if block_given?
      end
    end
      
and use the environment helpers

    config = Configuration.new do
      # add some custom environments from our app
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
    
    puts config.debug?
    puts config.caching?
    puts config.api_endpoint
