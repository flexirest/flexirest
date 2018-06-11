require 'spec_helper'

require 'active_model'

describe ActiveModel::Validations do
  class ActiveModelValidationsExample < Flexirest::BaseWithoutValidation
    include ActiveModel::Validations

    validates :first_name, :last_name, presence: true
    validates :password, length: { within: 6..12, message: 'Invalid password length, must be 6-12 characters' }
  end

  let(:first_name) { 'Foo '}
  let(:last_name) { 'Bar' }
  let(:password) { 'eiChahya6i' }
  let(:attributes) { { first_name: first_name, last_name: last_name, password: password } }
  subject(:instance) { ActiveModelValidationsExample.new(attributes) }

  it { is_expected.to be_valid }

  context 'when the first name is invalid' do
    let(:first_name) { '' }

    it { is_expected.to_not be_valid }
  end

  context 'when the last name is invalid' do
    let(:last_name) { '' }

    it { is_expected.to_not be_valid }
  end

  context 'when the password is invalid' do
    let(:password) { 'foo' }

    it { is_expected.to_not be_valid }

    it 'should include the custom error message' do
      instance.valid?

      expect(instance.errors[:password]).to include('Invalid password length, must be 6-12 characters')
    end
  end
end
