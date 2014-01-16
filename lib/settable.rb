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
    def initialize(namespace, &block)
      @block = lambda &block
      @namespace = namespace
      @environment = namespace.environment
    end

    def call
      @__env_return_value__ = nil # avoid using throw/catch
      default_return_value = instance_eval &@block
      @__env_return_value__ || default_return_value
    end

  private

    def root
      @namespace.root
    end

    def environment(name_or_names, value = nil, &block)
      return @__env_return_value__ if @__env_return_value__
      return unless @environment

      if Array(name_or_names).any?{ |n| @environment.call(n) }
        # store this and cache it so we can return it
        @__env_return_value__ = block_given? ? block.call : value
      end
    end
  end

  class Setting
    def initialize(namespace, key, value, &block)
      @key = key
      value = SettingBlock.new(namespace, &block) if block_given?
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
    attr_reader :name, :parent, :environment

    def initialize(name, parent = nil, &block)
      @name = name
      @environment = nil
      @parent = parent
      instance_eval &block
    end

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

    def set(name, value = nil, &block)
      setting =  Setting.new(self, name, value, &block)
      define_metaclass_method(name.to_sym){ setting.value }
      define_metaclass_method(:"#{name}?"){ setting.present? }
    end

    def namespace(name, &block)
      define_metaclass_method(name.to_sym) do
        namespace = Namespace.new(name, self, &block)
        namespace.use_environment(@environment)
        namespace
      end
    end

    def environment_matches?(*values)
      Array(values).any?{ |v| @environment.call(v) }
    end

    # bit of a hack to allow settings to reference other settings. will return the
    # toplevel namespace
    def root
      @root ||= begin
        root = self
        root = root.parent until root.parent.nil?
        root
      end
    end

  private

    def define_metaclass_method(method, &block)
      (class << self; self; end).__send__ :define_method, method, &block
    end
  end
end
