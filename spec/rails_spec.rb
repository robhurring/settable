require 'spec_helper'

module Rails
 class << self; attr_accessor :env; end
 self.env = :development
end

class RailsSettings
  include Settable
  include Settable::Rails

  def configure(&block)
    instance_eval &block
  end
end

describe RailsSettings do
  it_behaves_like 'a settable'

  let(:settings){ described_class.new }

  context 'environments' do
    it 'should recognize production' do
      Rails.env = :production
      settings.in_production?.should be_true
    end

    it 'should recognize development' do
      Rails.env = :development
      settings.in_development?.should be_true
    end

    it 'should recognize test' do
      Rails.env = :test
      settings.in_test?.should be_true
    end

    it 'should recognize custom environment' do
      settings.configure{ define_environments :custom }
      Rails.env = :custom

      settings.in_custom?.should be_true
    end
  end

  context 'namespaces' do
    before :all do
      settings.configure{ define_environments :custom }
      Rails.env = :custom
    end

    it 'should inherit custom environments' do
      settings.configure do
        namespace :group do
        end
      end

      settings.group.in_custom?.should be_true
    end
  end
end