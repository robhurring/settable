# Settings module that can be easily included into classes that store your
# applications configuration.
#
# Examples
#
#   $config = Settable.configure do
#     # basic set, similar to capistrano and sinatra
#     set :username, 'user'
#     set :password, 's3kr1t'
#
#     # namespace support to keep config clean
#     namespace :tracking do
#       set :enabled, true
#     end
#
#     set :block do
#       'blocks are allowed too!'
#     end
#   end
#
#   $config.username
#   # => 'user'
#
#   # Using presence methods, detect if theres a 'truthy' value
#   $config.username?
#   # => true
#
#   $config.tracking.enabled?
#   # => true
#
module Settable
  VERSION = '3.0.1'

  # name of the top-level namespace when none is provided
  ROOT_NAMESPACE = :__settable__

  # Mixin to make a settable DSL.
  #
  # Examples
  #
  #   class MyApp
  #      include Settable
  #
  #     settable :config do
  #       set :hello, 'world'
  #     end
  #   end
  #
  #   # can be used as a class method or an instance method
  #   MyApp.config == MyApp.new.config
  #   # => true
  #
  #   MyApp.config.hello
  #   # => 'world'
  #
  module DSL
    # Public: Mixin method to add the +settable+ class method.
    #
    # name  - The method name to store your settings under.
    # block - Your settings block.
    #
    # Examples
    #
    #   class MyApp
    #      include Settable
    #
    #     settable :settings do
    #       set :hello, 'world'
    #     end
    #   end
    #
    #   MyApp.settings.hello
    #   # => 'world'
    #
    # Creates a class and instance method with the name +name+ that contains
    # your settings.
    def settable(name, &block)
      metaclass = (class << self; self; end)
      metaclass.__send__(:define_method, name){ Namespace.new(name, &block) }
      self.__send__(:define_method, name){ self.class.__send__(name) }
    end
  end

  def self.included(base)
    base.extend DSL
  end

  # Public: Standalone configuration helper.
  #
  # block  - The settings block.
  #
  # Examples
  #
  #   $config = Settable.configure do
  #     set :hello, 'world'
  #   end
  #
  #   $config.hello
  #   # => 'world'
  #
  # Returns the settable object.
  def self.configure(&block)
    Namespace.new(ROOT_NAMESPACE, &block)
  end

  # Private: Environment testers for using the +environment+ helper methods within
  #         the settings.
  module Environment
    autoload :Rails, 'settable/environment/rails'
    autoload :Env, 'settable/environment/env'
  end

  # Private: Wrapper around the setting's value.
  # Returns the wrapped value.
  class SettingBlock
    # Public: Create a setting block in the given namespace.
    #
    # namespace  - The namespace to operate in.
    # block      - The block to call when retrieving the setting.
    #
    # Returns the setting value block.
    def initialize(namespace, &block)
      @block = lambda &block
      @namespace = namespace
      @environment = namespace.environment
    end

    # Public: Retrieve the value from this block, if we are using environment
    #         checkers then we will check the environment and override any
    #         default values
    #
    # Returns the value for the setting.
    def call
      @__env_return_value__ = nil # avoid using throw/catch
      default_return_value = instance_eval &@block
      @__env_return_value__ || default_return_value
    end

  private

    # Private: The root namespace, useful for calling back into other settings
    #          and retrieving their values.
    #
    # Returns the topmost namespace.
    def root
      @namespace.root
    end

    # Private: Override the default value if our environment matches the
    #          passed in arguments.
    #
    # name_or_names  - The values to match against our environment checker.
    # value          - A single value to return if the environment is matched.
    # block          - A block to run if the environment is matched.
    #
    # Examples
    #
    #   $config = Settable.configure do
    #     use_environment do |value|
    #       # value is given to us by the +environment+ helper below
    #       value.to_s == 'production'
    #     end
    #
    #     set :hello do
    #       environment :production, 'production'
    #       'world'
    #     end
    #   end
    #
    #   # returns production since our +use_environment's value+ will
    #   # come in as :production, and a match is made
    #   $config.hello
    #   # => 'production'
    #
    # Returns the value for the given environment, or nil if no environment
    # checker is being used or there isn't a match.
    def environment(name_or_names, value = nil, &block)
      return @__env_return_value__ if @__env_return_value__
      return unless @environment

      if Array(name_or_names).any?{ |n| @environment.call(n) }
        # store this and cache it so we can return it
        @__env_return_value__ = block_given? ? block.call : value
      end
    end
  end

  # Private: Wrapper around our settings.
  class Setting
    # Public: Create a new setting.
    #
    # namespace  - The namespace to create this setting in.
    # key        - The setting name.
    # value      - The value to return for this setting (if not block given).
    # block      - The block to run when this setting is retrieved.
    #
    # Examples
    #
    #   setting = Setting.new(namespace, :hello, 'world')
    #   setting.value
    #   # => 'world'
    #
    #   setting = Setting.new(namespace, :hello){ 'ohai' }
    #   setting.value
    #   # => 'ohai'
    #
    # Returns the setting object.
    def initialize(namespace, key, value, &block)
      @key = key
      value = SettingBlock.new(namespace, &block) if block_given?
      @value = value
    end

    # Public: Retrieve the settings value. If a block was given in the
    #         constructor, it runs the block - otherwise it will return
    #         the value given in the constructor.
    #
    # Returns the value.
    def value
      if @value.respond_to?(:call)
        @value.call
      else
        @value
      end
    end

    # Public: Presence method for the setting.
    # Returns the truthiness of the value.
    def present?
      !!value
    end
  end

  # Private: A container for multiple settings. Every setting belongs to a
  #          namespace group.
  class Namespace
    attr_reader :name, :parent, :environment

    # Public: Create a new namespace to store settings in. Namespaces inherit
    #         their parent's environment checker by default, but that may be
    #         overridden using +use_environment+
    #
    # name    - The namespace name.
    # parent  - The parent namespace when nesting namespaces.
    # block   - A block containing all your +set+ calls
    #
    # Examples
    #
    #   namespace = Namespace.new(:global, nil) do
    #     set :hello, 'world'
    #   end
    #
    #   namespace.hello
    #   # => 'world'
    #
    # Returns the namespace to attach settings to.
    def initialize(name, parent = nil, &block)
      @name = name
      @environment = parent ? parent.environment : nil
      @parent = parent
      instance_eval &block
    end

    # Public: A custom checker when using the Setting's +environment+ helper.
    #         You can pass a block in which will receive the +environment+ value
    #         and should return a true/false to indicate a match. All nested
    #         namespaces will inherit their parent environment by default.
    #
    # klass  - A Class which responds to a #call(value) method, or a symbol of
    #          either :rails, or :env for builtin testers
    # block  - A block that will be called with the environment to see if it is
    #          a match.
    #
    # Examples
    #
    #   # check if the given value is in our ENV
    #   namespace.use_environment{ |value| ENV.has_key?(value) }
    #
    #   # use the built-in tester that looks at Rails.env
    #   namespace.use_environment(:rails)
    #
    #   # use a custom class that responds to #call(value)
    #   namespace.use_environment(MyCustomChecker.new)
    #
    # Returns the duplicated String.
    def use_environment(klass = nil, &block)
      if klass.nil?
        if block_given?
          klass = block
        else
          return
        end
      elsif klass.is_a?(Symbol)
        klass = Object.module_eval("Settable::Environment::#{klass.to_s.capitalize}", __FILE__, __LINE__)
      else
        unless klass.is_a?(Object) && klass.respond_to?(:call)
          raise "#{klass} must respond to #call(value) to be a valid environment!"
        end
      end

      @environment = klass
    end

    # Public: Create a setting method and its 'presence' method.
    #
    # name  - The setting name.
    # value - The settings value (unless a block is given).
    # block - The block to run for this setting's value
    #
    # Examples
    #
    #   $config = Settable.configure do
    #     set :hello, 'world'
    #   end
    #   $config.hello
    #   # => 'world'
    #
    #   $config.hello?
    #   # => true
    #
    #   $config = Settable.configure do
    #     set(:hello){ 'world' }
    #   end
    #   $config.hello
    #   # => 'world'
    #
    # Returns nothing.
    def set(name, value = nil, &block)
      setting = Setting.new(self, name, value, &block)
      define_metaclass_method(name.to_sym){ setting.value }
      define_metaclass_method(:"#{name}?"){ setting.present? }
    end

    # Public: Create a nested namespace.
    #
    # name  - The name for the namespace.
    # block - A block to run in this namespace's context.
    #
    # Examples
    #
    #   $config = Settable.configure do
    #     set :username, 'user'
    #
    #     namespace :api do
    #       set :username, 'api-user'
    #     end
    #   end
    #
    #   $config.username
    #   # => 'user'
    #
    #   $config.api.username
    #   # => 'api-user'
    #
    # Returns nothing.
    def namespace(name, &block)
      define_metaclass_method(name.to_sym) do
        namespace = Namespace.new(name, self, &block)
        namespace
      end
    end

    # Public: Helper method for setting values based off our +environment+.
    #
    # values  - An array of values to check against our +environment+
    #
    # Examples
    #
    #   $config = Settable.configure do
    #     use_environment :rails
    #     set :google_analytics, environment_matches?(:production, :staging)
    #   end
    #
    #   Rails.env = "production" # (or Rails.env = "staging")
    #   $config.google_analytics?
    #   # => true
    #
    #   Rails.env = "development"
    #   $config.google_analytics?
    #   # => false
    #
    # Returns true if our environment matches any of our +values+.
    def environment_matches?(*values)
      Array(values).any?{ |v| @environment.call(v) }
    end

    # Public: Find the top-most namespace and return it.
    # Examples
    #
    #   $config = Settable.configure do
    #     set :hello, 'world'
    #
    #     namespace :a do
    #       namespace :b do
    #         set(:test){ root.hello }
    #       end
    #     end
    #   end
    #
    #   $config.a.b.test
    #   # => 'world'
    #
    # Returns the topmost namespace.
    def root
      @root ||= begin
        root = self
        root = root.parent until root.parent.nil?
        root
      end
    end

  private

    # Private: Create a method on the metaclass.
    #
    # method  - Method name.
    # block   - Method body.
    #
    # Returns nothing.
    def define_metaclass_method(method, &block)
      (class << self; self; end).__send__ :define_method, method, &block
    end
  end
end
