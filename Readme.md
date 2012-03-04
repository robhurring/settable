About
===

Simple library to make configuration files dead simple. It uses "set, enable, disable" just like capistrano and sinatra. It also has some rails helpers to change settings based off environments.

To create the configuration wrapper, its as simple as:

    class Configuration
      include Settable
      make_settable

      enable :debugging
      set :logfile, 'my/logfile.log'

      namespace :api do
        set :key, 'abcdefg'
        set :secret, '123567678'
      end
    end

To use you can call:

    Configuration.debugging?    # => true
    Configuration.api.key       # => "abcdefg"

Usage with rails is also supported, which makes app configuration between environments a cinch.

    class RailsConfiguration
      include Settable
      include Settable::Rails
      make_settable

      enable :logging

      set :error_reporting, in_production?

      namespace :seo do
        # true if in production or certification
        set :tracking, in_environments?(:production, :certification)
      end

      namespace :api do
        set :token do
          in_production{ return 'prodtoken' }
          'devtoken'
        end
      end
    end

    RailsConfiguration.logging?           # => true
    RailsConfiguration.error_reporting    # => true (if in prodtoken)
    RailsConfiguration.api.token          # => 'prodtoken' (if in production, else 'devtoken')

Note: custom environments don't work when using settables at the class level right now. There is an alternate
way of using this lib if you need multiple, separate, configs in your app

    # To use instances rather than classes leave out the 'make_settable' call
    class Configuration
      include Settable
      include Settable::Rails

      def initialize(&block)
        instance_eval &block
      end
    end

    # in an initializer or wherever
    $app_config = Configuration.new do
      set :key, 'value'
    end

    $seo_config = Configuration.new do
      enable :tracking
    end
