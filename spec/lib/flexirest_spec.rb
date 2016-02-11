require 'spec_helper'

describe Flexirest do

  after(:each) do
    # Reload Module after each test to ensure name variable is reset to default
    load 'flexirest.rb'
  end

  it "should be named Flexirest" do
    expect(Flexirest.name).to eq('Flexirest')
  end

  it "should allow setting to something else" do
    Flexirest.name = 'SomethingElse'
    expect(Flexirest.name).to eq('SomethingElse')
  end

end
