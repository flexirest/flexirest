require 'spec_helper'

class EmptyExample < Flexirest::BaseWithoutValidation
  whiny_missing true
end

describe Flexirest::BaseWithoutValidation do
  it 'should support hash resolving' do
    h = {}
    expect{ h[EmptyExample.new] = 'not important' }.to_not raise_error
  end
end