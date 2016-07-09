require 'spec_helper'

class AttributeParsingExampleBase
  include Flexirest::AttributeParsing

  def test(v)
    parse_attribute_value(v)
  end
end


describe Flexirest::AttributeParsing do
  let(:subject) { AttributeParsingExampleBase.new }

  it "should parse datetimes" do
    expect(subject.test("1980-12-24T00:00:00.000Z")).to be_a(DateTime)
  end

  it "should parse dates" do
    expect(subject.test("1980-12-24")).to be_a(Date)
  end

  it "should not parse a multiline string as a datetime" do
    expect(subject.test("not a date\n1980-12-24")).to be_a(String)
  end

  it "should return strings for string values" do
    expect(subject.test("1980-12")).to eq("1980-12")
  end

  it "should return integers for integer values" do
    expect(subject.test(1980)).to eq(1980)
  end

  it "should return floats for float values" do
    expect(subject.test(1980.12)).to eq(1980.12)
  end
end
