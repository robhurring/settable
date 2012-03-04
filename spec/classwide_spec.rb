require 'spec_helper'

class Settings
  include Settable
  make_settable
end

describe Settings do
  it 'should be possible' do
    Settings.set :key, 'value'
    Settings.key.should eq('value')
  end

  it 'should handle blocks' do
    Settings.set :key do
      'value'
    end

    Settings.key.should eq('value')
  end

  it 'should handle namespaces' do
    Settings.namespace :group do
      set :key, 'value'
    end
    Settings.group.key.should eq('value')
  end
end