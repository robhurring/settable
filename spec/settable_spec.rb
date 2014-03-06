require 'spec_helper'

describe 'Basic Usage' do
  it 'should allow setting' do
    c = Settable.configure do
      set :key, 'value'
    end

    c.key.should eq 'value'
  end

  it 'should allow block settings' do
    c = Settable.configure do
      set :key do
        'value'
      end
    end

    c.key.should eq 'value'
  end

  it 'should have truthy methods' do
    c = Settable.configure do
      set :key do
        'value'
      end
    end

    c.key?.should be_true
  end
end

describe Settable::Namespace do
  it 'should create a namespace' do
    c = Settable.configure do
      namespace :test do
        set :key, 'value'
      end
    end

    c.test.key.should eq 'value'
  end

  it 'should support nesting' do
    c = Settable.configure do
      namespace :a do
        namespace :b do
          set :key, 'value'
        end
      end
    end

    c.a.b.key.should eq 'value'
  end
end

describe Settable::Environment do
  module EnvTester
    def self.call(environment)
      environment.to_sym == :test
    end
  end

  it 'should check the environment' do
    c = Settable.configure do
      use_environment EnvTester

      set :key do
        environment :test, 'value'
        'default'
      end
    end

    c.key.should eq 'value'
  end

  it 'should handle false correctly from env' do
    c = Settable.configure do
      use_environment EnvTester

      set :something_enabled do
        environment :test, false
        true
      end
    end

    c.something_enabled.should be_false
  end

  it 'should default unless matched' do
    c = Settable.configure do
      use_environment EnvTester

      set :key do
        environment :bad_environment, 'value'
        'default'
      end
    end

    c.key.should eq 'default'
  end
end

describe Settable::Environment::Env do
  subject do
    Settable.configure do
      use_environment :env

      set :key do
        environment :TEST, 'test found!'
        'default'
      end
    end
  end

  it 'should find matching key in ENV' do
    ENV['TEST'] = '1'
    subject.key.should eq 'test found!'
  end

  it 'should not find matching key in ENV' do
    ENV.delete('TEST')
    subject.key.should eq 'default'
  end
end

describe Settable::Environment::Rails do
  module ::Rails
    def self.env=(env)
      @env = env
    end

    def self.env
      @env
    end
  end

  subject do
    Settable.configure do
      use_environment :rails

      set :key do
        environment [:qa, :staging], 'qa_or_staging'
        environment :development, 'development'
        environment :production, 'production'
        environment :test, 'test'
        environment(:block){ 'block' }

        'default'
      end

      namespace :segment do
        set :key do
          environment [:qa, :staging], 'qa_or_staging'
          environment :development, 'development'
          environment :production, 'production'
          environment :test, 'test'
          environment(:block){ 'block' }

          'default'
        end
      end
    end
  end

  describe '#environment_matches?' do
    it 'should return false when not set' do
      subject.instance_eval do
        set :test, environment_matches?(:qa, :staging)
      end

      subject.test.should be_false
    end

    it 'should return true when set' do
      Rails.env = :qa

      subject.instance_eval do
        set :test, environment_matches?(:qa, :staging)
      end

      subject.test.should be_true
    end
  end

  it 'should match arrays' do
    Rails.env = :qa
    subject.key.should eq 'qa_or_staging'
    subject.segment.key.should eq 'qa_or_staging'

    Rails.env = :staging
    subject.key.should eq 'qa_or_staging'
    subject.segment.key.should eq 'qa_or_staging'
  end

  it 'should match development' do
    Rails.env = :development
    subject.key.should eq 'development'
    subject.segment.key.should eq 'development'
  end

  it 'should match production' do
    Rails.env = :production
    subject.key.should eq 'production'
    subject.segment.key.should eq 'production'
  end

  it 'should match test' do
    Rails.env = :test
    subject.key.should eq 'test'
    subject.segment.key.should eq 'test'
  end

  it 'should not match bad environments' do
    Rails.env = :unknown_bad_environment
    subject.key.should eq 'default'
    subject.segment.key.should eq 'default'
  end

  it 'should handle blocks' do
    Rails.env = :block
    subject.key.should eq 'block'
    subject.segment.key.should eq 'block'
  end
end

describe Settable::DSL do
  class TestConfig1
    include Settable

    settable :config do
      set :hello, 'world'
    end

    def something
      config.hello
    end
  end

  it 'instances methods should have access' do
    TestConfig1.new.something.should eq 'world'
  end

  it 'class should have access' do
    TestConfig1.config.hello.should eq 'world'
  end

  it 'instnace should have generated method' do
    TestConfig1.new.config.should be_kind_of(Settable::Namespace)
  end
end

describe 'Interpolating config' do
  class TestConfig2
    include Settable

    settable :config do
      set :hello, "hello"
      set :hello_world, "#{hello} world!"

      set :hello_world_block do
        "#{root.hello} world!"
      end
    end
  end

  it 'should interpolate values from config' do
    TestConfig2.config.hello_world.should eq 'hello world!'
  end

  it 'should interpolate values from config (within a block)' do
    TestConfig2.config.hello_world_block.should eq 'hello world!'
  end
end
