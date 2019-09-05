module Flexirest::ActiveModelFormSupport
  extend ActiveSupport::Concern
  include ActiveModel::AttributeAssignment
  include ActiveModel::Validations
  include ActiveModel::Conversion

  included do
    extend ActiveModel::Naming
    extend ActiveModel::Translation
  end

  def persisted?
    !dirty?
  end

  def new_record?
    id.blank?
  end

  def errors
    ActiveSupport::HashWithIndifferentAccess.new([]).merge(self[:errors] || {})
  end
end
