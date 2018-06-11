require 'spec_helper'

class EmptyBaseExample < Flexirest::Base
end

describe Flexirest::Base do
  subject { EmptyBaseExample.new }

  it { is_expected.to respond_to(:valid?) }
end
