$:.push File.expand_path("../../lib", __FILE__)
require 'settable'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end

shared_examples_for 'a settable' do
    let(:settings){ Settings.new }

  context 'basic values' do
    it 'should be set without block' do
      settings.set :key, 'value'
      settings.key.should eq('value')
    end

    it 'should be set with blocks' do
      settings.set :key do
        'value'
      end

      settings.key.should eq('value')
    end
  end

  context 'instance evalulating' do
    it 'should set using strings' do
      settings.configure do
        set :key, 'value'
      end

      settings.key.should eq('value')
    end

    it 'should set using blocks' do
      settings.configure do
        set :key do
          'value'
        end
      end

      settings.key.should eq('value')
    end
  end

  context 'namespaces' do
    it 'should set using strings' do
      settings.configure do
        namespace :group do
          set :key, 'value'
        end
      end

      settings.group.key.should eq('value')
    end

    it 'should set using blocks' do
      settings.configure do
        namespace :group do
          set :key do
            'value'
          end
        end
      end

      settings.group.key.should eq('value')
    end
  end
end
