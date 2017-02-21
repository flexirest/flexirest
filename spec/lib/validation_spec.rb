require 'spec_helper'

describe "Flexirest::Validation" do
  class SimpleValidationExample < OpenStruct
    include Flexirest::Validation
    validates :first_name, presence: true, message: "Sorry, something went wrong"
    validates :middle_name, length: { minimum: 2, maximum: 30 }, allow_nil: true
    validates :last_name, existence: true
    validates :nick_name, length: { minimum: 2, maximum: 30 }
    validates :alias, length: { minimum: 2, maximum: 30 }, allow_nil: false
    validates :password, length: { within: 6..12 }
    validates :post_code, length: { minimum: 6, maximum: 8 }
    validates :salary, numericality: true, minimum: 20_000, maximum: 50_000
    validates :age, numericality: { minimum: 18, maximum: 65 }
    validates :suffix, inclusion: { in: %w{Dr. Mr. Mrs. Ms.}}
    validates :golf_score, numericality: true, allow_nil: true
    validates :retirement_age, numericality: { minimum: 65 }, allow_nil: true
    validates :cars_owned, numericality: true
    validates :houses_owned, numericality: true, allow_nil: false
    validates :favorite_authors, inclusion: { in: ["George S. Klason", "Robert T. Kiyosaki", "Lee Child"] }, allow_nil: true
    validates :favorite_artists, inclusion: { in: ["Claude Monet", "Vincent Van Gogh", "Andy Warhol"] }
    validates :favorite_composers, inclusion: { in: ["Mozart", "Bach", "Pachelbel", "Beethoven"] }, allow_nil: false
  end

  it "should be able to register a validation" do
    expect(SimpleValidationExample._validations.size).to eq(17)
  end

  context "when validating presence" do
    it "should be invalid if a required value isn't present" do
      a = SimpleValidationExample.new
      a.first_name = nil
      a.valid?
      expect(a._errors[:first_name].size).to eq(1)
    end

    it "should return a custom error if specified and a validation fails" do
      a = SimpleValidationExample.new
      a.first_name = nil
      a.valid?
      expect(a._errors[:first_name][0]).to eq("Sorry, something went wrong")
    end

    it "should be invalid if a required value is present but blank" do
      a = SimpleValidationExample.new
      a.first_name = ""
      a.valid?
      expect(a._errors[:first_name].size).to eq(1)
    end

    it "should be invalid if a required value is present but is an empty array" do
      a = SimpleValidationExample.new
      a.first_name = []
      a.valid?
      expect(a._errors[:first_name].size).to eq(1)
    end

    it "should be invalid if a required value is present but is an empty hash" do
      a = SimpleValidationExample.new
      a.first_name = {}
      a.valid?
      expect(a._errors[:first_name].size).to eq(1)
    end

    it "should be valid if a required value is present" do
      a = SimpleValidationExample.new
      a.first_name = "John"
      a.valid?
      expect(a._errors[:first_name]).to be_empty
    end
  end

  context "when validating existence" do
    it "should be invalid if a required value isn't present" do
      a = SimpleValidationExample.new
      a.last_name = nil
      a.valid?
      expect(a._errors[:last_name].size).to eq(1)
    end

    it "should be valid if a required value is present but blank" do
      a = SimpleValidationExample.new
      a.last_name = ""
      a.valid?
      expect(a._errors[:last_name]).to be_empty
    end

    it "should be valid if a required value is present" do
      a = SimpleValidationExample.new
      a.last_name = "John"
      a.valid?
      expect(a._errors[:last_name]).to be_empty
    end
  end

  context "when validating length" do
    it "should be invalid if a length within value is outside the range" do
      a = SimpleValidationExample.new(password:"12345")
      a.valid?
      expect(a._errors[:password].size).to eq(1)
    end

    it "should be valid if a length within value is inside the range" do
      a = SimpleValidationExample.new(password:"123456")
      a.valid?
      expect(a._errors[:password].size).to eq(0)
    end

    it "should be invalid if a length is below the minimum" do
      a = SimpleValidationExample.new(post_code:"12345")
      a.valid?
      expect(a._errors[:post_code].size).to eq(1)
    end

    it "should be valid if a length is above or equal to the minimum and below the maximum" do
      a = SimpleValidationExample.new(post_code:"123456")
      a.valid?
      expect(a._errors[:post_code].size).to eq(0)
    end

    it "should be invalid if a length is above the maximum" do
      a = SimpleValidationExample.new(post_code:"123456789")
      a.valid?
      expect(a._errors[:post_code].size).to eq(1)
    end

    it "should be valid if a length is nil and allow_nil option is true" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a._errors[:middle_name]).to be_empty
    end

    it "should be invalid if a length is nil and allow_nil option is not provided" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a._errors[:nick_name].size).to eq(1)
    end

    it "should be invalid if a length is nil and allow_nil option is false" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a._errors[:alias].size).to eq(1)
    end
  end


  context "when validating numericality" do
    context "using the original format with min and max as types" do
      it "should be able to validate that a field is numeric" do
        a = SimpleValidationExample.new(salary:"Bob")
        a.valid?
        expect(a._errors[:salary].size).to be > 0
      end

      it "should be able to validate that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(salary:10_000)
        a.valid?
        expect(a._errors[:salary].size).to be > 0
      end

      it "should be able to validate that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(salary:100_000)
        a.valid?
        expect(a._errors[:salary].size).to be > 0
      end

      it "should be valid that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(salary:30_000)
        a.valid?
        expect(a._errors[:salary].size).to eq(0)
      end

      it "should be valid if a value is nil and allow_nil option is true" do
        a = SimpleValidationExample.new
        a.valid?
        expect(a._errors[:golf_score]).to be_empty
      end

      it "should be valid if a value is nil and allow_nil option is true and a hash of options is passed to numericality" do
        a = SimpleValidationExample.new
        a.valid?
        expect(a._errors[:retirement_age]).to be_empty
      end

      it "should be invalid if a value is nil and allow_nil option is not provided" do
        a = SimpleValidationExample.new
        a.valid?
        expect(a._errors[:cars_owned].size).to eq(1)
      end

      it "should be invalid if a value is nil and allow_nil option is false" do
        a = SimpleValidationExample.new
        a.valid?
        expect(a._errors[:houses_owned].size).to eq(1)
      end
    end

    context "using the original format with min and max as types" do
      it "should be able to validate that a field is numeric" do
        a = SimpleValidationExample.new(age:"Bob")
        a.valid?
        expect(a._errors[:age].size).to be > 0
      end

      it "should be able to validate that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(age: 17)
        a.valid?
        expect(a._errors[:age].size).to be > 0
      end

      it "should be able to validate that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(age: 70)
        a.valid?
        expect(a._errors[:age].size).to be > 0
      end

      it "should be valid that a numeric field is above or equal to a minimum" do
        a = SimpleValidationExample.new(age: 30)
        a.valid?
        expect(a._errors[:age].size).to eq(0)
      end
    end
  end

  context "when validating inclusion" do
    it "should be invalid if the value is not contained in the list" do
      a = SimpleValidationExample.new(suffix: "Baz")
      a.valid?
      expect(a._errors[:suffix].size).to be > 0
    end

    it "should be valid if the value is contained in the list" do
      a = SimpleValidationExample.new(suffix: "Dr.")
      a.valid?
      expect(a._errors[:suffix].size).to eq(0)
    end

    it "should be valid if the value is nil and allow_nil option is true" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a._errors[:favorite_authors]).to be_empty
    end

    it "should be invalid if the value is nil and allow_nil option is not provided" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a._errors[:favorite_artists].size).to eq(1)
    end

    it "should be invalid if the value is nil and allow_nil option is false" do
      a = SimpleValidationExample.new
      a.valid?
      expect(a._errors[:favorite_composers].size).to eq(1)
    end
  end

  context "when passing a block" do
    it "should be invalid when a block adds an error" do
      class ValidationExample1 < OpenStruct
        include Flexirest::Validation
        validates :first_name do |object, name, value|
          object._errors[name] << "must be over 4 chars long" if value.length <= 4
        end
      end
      a = ValidationExample1.new(first_name:"John")
      a.valid?
      expect(a._errors[:first_name].size).to eq(1)
    end

    it "should be valid when a block doesn't add an error" do
      class ValidationExample2 < OpenStruct
        include Flexirest::Validation
        validates :first_name do |object, name, value|
          object._errors[name] << "must be over 4 chars long" if value.length <= 4
        end
      end
      a = ValidationExample2.new(first_name:"Johnny")
      a.valid?
      expect(a._errors[:first_name]).to be_empty
    end
  end

  describe "#full_error_messages" do
    it "should return an array of strings that combines the attribute name and the error message" do
      a = SimpleValidationExample.new(age:"Bob", suffix: "Baz")
      a.valid?
      expect(a.full_error_messages).to include("age must be numeric")
      expect(a.full_error_messages).to include("suffix must be included in Dr., Mr., Mrs., Ms.")
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
