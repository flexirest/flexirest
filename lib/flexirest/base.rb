module Flexirest
  class Base < BaseWithoutValidation
    include Validation

    def initialize(attrs={})
      raise Exception.new("Cannot instantiate Base class") if self.class == Flexirest::Base
      super
    end

    def errors
      @attributes[:errors] || (_errors != {} ? _errors : nil)
    end
  end
end
