require 'spec_helper'

describe "ActiveModel::Validations integration" do
  class SimpleValidationExample < Flexirest::Base

    validates :first_name, presence: { message: "Sorry, something went wrong" }
    validates :middle_name, length: { minimum: 2, maximum: 30, allow_nil: true }
    validates :nick_name, length: { minimum: 2, maximum: 30 }
    validates :alias, length: { minimum: 2, maximum: 30, allow_nil: false }
    validates :password, length: { within: 6..12 }
    validates :post_code, length: { minimum: 6, maximum: 8 }
    validates :salary, numericality: { greater_than_or_equal_to: 20_000, less_than_or_equal_to: 50_000 }
    validates :age, numericality: { greater_than_or_equal_to: 18, less_than_or_equal_to: 65 }
    validates :suffix, inclusion: { in: %w{Dr. Mr. Mrs. Ms.}}
    validates :golf_score, numericality: { allow_nil: true }
    validates :retirement_age, numericality: { greater_than_or_equal_to: 65, allow_nil: true }
    validates :cars_owned, numericality: true
    validates :houses_owned, numericality: { allow_nil: false }
    validates :favorite_authors, inclusion: { in: ["George S. Klason", "Robert T. Kiyosaki", "Lee Child"], allow_nil: true }
    validates :favorite_artists, inclusion: { in: ["Claude Monet", "Vincent Van Gogh", "Andy Warhol"] }
    validates :favorite_composers, inclusion: { in: ["Mozart", "Bach", "Pachelbel", "Beethoven"], allow_nil: false }
  end

  context "when validating presence" do
    it "should be invalid if a required value isn't present" do
      a = SimpleValidationExample.new
      a.first_name = nil
      a.valid?
      expect(a.errors[:first_name].size).to eq(1)
    end

    it "should return a custom error if specified and a validation fails" do
      a = SimpleValidationExample.new
      a.first_name = nil
      a.valid?
      expect(a.errors[:first_name][0]).to eq("Sorry, something went wrong")
    end

    it "should be invalid if a required value is present but blank" do
      a = SimpleValidationExample.new
      a.first_name = ""
      a.valid?
      expect(a.errors[:first_name].size).to eq(1)
    end

    it "should be invalid if a required value is present but is an empty array" do
      a = SimpleValidationExample.new
      a.first_name = []
      a.valid?
      expect(a.errors[:first_name].size).to eq(1)
    end

    it "should be invalid if a required value is present but is an empty hash" do
      a = SimpleValidationExample.new
      a.first_name = {}
      a.valid?
      expect(a.errors[:first_name].size).to eq(1)
    end

    it "should be valid if a required value is present" do
      a = SimpleValidationExample.new
      a.first_name = "John"
      a.valid?
      expect(a.errors[:first_name]).to be_empty
    end
  end

  context "when validating length" do
    it "should be invalid if a length within value is outside the range" do
      a = SimpleValidationExample.new(password:"12345")
      a.valid?
      expect(a.errors[:password].size).to eq(1)
    end

    it "should be valid if a length within value is inside the range" do
      a = SimpleValidationExample.new(password:"123456")
      a.valid?
      expect(a.errors[:password].size).to eq(0)
    end

    it "should be invalid if a length is below the minimum" do
      a = SimpleValidationExample.new(post_code:"12345")
      a.valid?
      expect(a.errors[:post_code].size).to eq(1)
    end

    it "should be valid if a length is above or equal to the minimum and below the maximum" do
      a = SimpleValidationExample.new(post_code:"123456")
      a.valid?
      expect(a.errors[:post_code].size).to eq(0)
    end

    it "should be invalid if a length is above the maximum" do
      a = SimpleValidationExample.new(post_code:"123456789")
      a.valid?
      expect(a.errors[:post_code].size).to eq(1)
    end

    it "should be valid if a length is nil and allow_nil option is true" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a.errors[:middle_name]).to be_empty
    end

    it "should be invalid if a length is nil and allow_nil option is not provided" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a.errors[:nick_name].size).to eq(1)
    end

    it "should be invalid if a length is nil and allow_nil option is false" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a.errors[:alias]).to_not be_empty
    end
  end


  context "when validating numericality" do
    context "using the original format with min and max as types" do
      it "should be able to validate that a field is numeric" do
        a = SimpleValidationExample.new(salary:"Bob")
        a.valid?
        expect(a.errors[:salary].size).to be > 0
      end

      it "should be able to validate that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(salary:10_000)
        a.valid?
        expect(a.errors[:salary].size).to be > 0
      end

      it "should be able to validate that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(salary:100_000)
        a.valid?
        expect(a.errors[:salary].size).to be > 0
      end

      it "should be valid that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(salary:30_000)
        a.valid?
        expect(a.errors[:salary].size).to eq(0)
      end

      it "should be valid if a value is nil and allow_nil option is true" do
        a = SimpleValidationExample.new
        a.valid?
        expect(a.errors[:golf_score]).to be_empty
      end

      it "should be valid if a value is nil and allow_nil option is true and a hash of options is passed to numericality" do
        a = SimpleValidationExample.new
        a.valid?
        expect(a.errors[:retirement_age]).to be_empty
      end

      it "should be invalid if a value is nil and allow_nil option is not provided" do
        a = SimpleValidationExample.new
        a.valid?
        expect(a.errors[:cars_owned].size).to eq(1)
      end

      it "should be invalid if a value is nil and allow_nil option is false" do
        a = SimpleValidationExample.new
        a.valid?
        expect(a.errors[:houses_owned].size).to eq(1)
      end
    end

    context "using the original format with min and max as types" do
      it "should be able to validate that a field is numeric" do
        a = SimpleValidationExample.new(age:"Bob")
        a.valid?
        expect(a.errors[:age].size).to be > 0
      end

      it "should be able to validate that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(age: 17)
        a.valid?
        expect(a.errors[:age].size).to be > 0
      end

      it "should be able to validate that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(age: 70)
        a.valid?
        expect(a.errors[:age].size).to be > 0
      end

      it "should be valid that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(age: 30)
        a.valid?
        expect(a.errors[:age].size).to eq(0)
      end
    end
  end

  context "when validating inclusion" do
    it "should be invalid if the value is not contained in the list" do
      a = SimpleValidationExample.new(suffix: "Baz")
      a.valid?
      expect(a.errors[:suffix].size).to be > 0
    end

    it "should be valid if the value is contained in the list" do
      a = SimpleValidationExample.new(suffix: "Dr.")
      a.valid?
      expect(a.errors[:suffix].size).to eq(0)
    end

    it "should be valid if the value is nil and allow_nil option is true" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a.errors[:favorite_authors]).to be_empty
    end

    it "should be invalid if the value is nil and allow_nil option is not provided" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a.errors[:favorite_artists].size).to eq(1)
    end

    it "should be invalid if the value is nil and allow_nil option is false" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a.errors[:favorite_composers].size).to eq(1)
    end
  end

  context "when passing a block" do
    it "should be invalid when a block adds an error" do
      class ValidationExample1 < Flexirest::Base
        validate do
          errors.add(:first_name, "must be over 4 chars long") if first_name.length <= 4
        end
      end
      a = ValidationExample1.new(first_name: "John")
      a.valid?
      expect(a.errors[:first_name].size).to eq(1)
    end
  end

  describe "#full_error_messages" do
    it "should return an array of strings that combines the attribute name and the error message" do
      a = SimpleValidationExample.new(age: "Bob", suffix: "Baz")
      a.valid?
      expect(a.errors.full_messages).to include("Age is not a number")
      expect(a.errors.full_messages).to include("Suffix is not included in the list")
    end
  end

  it "should call valid? before making a request" do
    class ValidationExample3 < Flexirest::Base
      whiny_missing true
      post :create, '/'
      validates :name, presence:true
    end

    expect_any_instance_of(ValidationExample3).to receive(:valid?)
    object = ValidationExample3.new
    expect { object.create }.to raise_exception(Flexirest::ValidationFailedException)
  end
end
