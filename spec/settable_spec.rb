require 'spec_helper'

class Settings
  include Settable

  def configure(&block)
    instance_eval &block
  end
end

describe Settings do
  it_behaves_like 'a settable'
end