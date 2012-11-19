# Settable
# Settings module that can be easily included into classes that store
# your applications configuration
module Settable
  VERSION = '3.0'
  ROOT_NAMESPACE = :__settable__

  module DSL
    def settable(name, &block)
      metaclass = (class << self; self; end)
      metaclass.__send__(:define_method, name){ Namespace.new(name, &block) }
      self.__send__(:define_method, name){ self.class.__send__(name) }
    end
  end

  def self.included(base)
    base.extend DSL
  end

  def self.configure(&block)
    Namespace.new(ROOT_NAMESPACE, &block)
  end

  module Environment
    autoload :Rails, 'settable/environment/rails'
    autoload :Env, 'settable/environment/env'
  end

  class SettingBlock
    def initialize(environment = nil, &block)
      @block = lambda &block
      @environment = environment
    end

    def call
      catch(:done){ instance_eval &@block }
    end

  private

    def environment(name_or_names, value = nil, &block)
      return unless @environment

      if Array(name_or_names).any?{ |n| @environment.matches?(n) }
        return_value = block_given? ? block.call : value
        throw :done, return_value
      end
    end
  end

  class Setting
    def initialize(namespace, key, value, &block)
      @key = key
      value = SettingBlock.new(namespace.environment, &block) if block_given?
      @value = value
    end

    def value
      if @value.respond_to?(:call)
        @value.call
      else
        @value
      end
    end

    def present?
      !!value
    end
  end

  class Namespace
    attr_reader :environment

    def initialize(name, &block)
      @name = name
      @environment = nil
      instance_eval &block
    end

    def use_environment(klass = nil)
      return if klass.nil?

      if klass.is_a?(Symbol)
        klass = Object.module_eval("Settable::Environment::#{klass.to_s.capitalize}", __FILE__, __LINE__)
      else
        unless klass.is_a?(Object) && klass.respond_to?(:matches?)
          raise "#{klass} must respond to #matches?(value) to be a valid environment!"
        end
      end

      @environment = klass
    end

    def set(name, value = nil, &block)
      setting =  Setting.new(self, name, value, &block)
      define_metaclass_method(name.to_sym){ setting.value }
      define_metaclass_method(:"#{name}?"){ setting.present? }
    end

    def namespace(name, &block)
      define_metaclass_method(name.to_sym) do
        namespace = Namespace.new(name, &block)
        namespace.use_environment(@environment)
        namespace
      end
    end

    def environment_matches?(*values)
      Array(values).any?{ |v| @environment.matches?(v) }
    end

  private

    def define_metaclass_method(method, &block)
      (class << self; self; end).__send__ :define_method, method, &block
    end
  end
end
