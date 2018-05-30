require 'spec_helper'

class AssociationExampleNested < Flexirest::Base
end

class AssociationExampleOther < Flexirest::Base
  has_many :nested, AssociationExampleNested
  has_one :nested_child, AssociationExampleNested
end

class AssociationExampleBase < Flexirest::Base
  has_many :others, AssociationExampleOther
  has_many :association_example_others

  has_one :child, AssociationExampleOther
  has_one :association_example_other
end

class DeepNestedHasManyChildExample < Flexirest::BaseWithoutValidation
end

class DeepNestedHasManyTopExample < Flexirest::BaseWithoutValidation
  has_many :entries, DeepNestedHasManyChildExample
end

class DeepNestedHasManyExample < Flexirest::BaseWithoutValidation
  has_many :results, DeepNestedHasManyTopExample
  hash = { results: [ { entries: [ { items: [ "item one", "item two" ] } ] }, { entries: [ { items: [ "item three", "item four" ] } ] } ] }
  get :find, "/iterate", fake: hash.to_json
end

class WhitelistedDateExample < Flexirest::BaseWithoutValidation
  parse_date :updated_at
end

class WhitelistedDateMultipleExample < Flexirest::BaseWithoutValidation
  parse_date :updated_at, :created_at
  parse_date :generated_at
end


describe "Has Many Associations" do
  let(:subject) {AssociationExampleBase.new}

  it "should return the attribute if it's not an iterable type" do
    subject.others = "foo"
    expect(subject.others).to eq("foo")
  end

  it "should return the attribute if it's an empty array" do
    subject.others = []
    expect(subject.others).to eq([])
  end

  it "should return a list of the association class" do
    subject.others = [{test: "foo"}]
    expect(subject.others.first).to be_an(AssociationExampleOther)
  end

  it "should return correctly instantiated association classes" do
    subject.others = [{test: "foo"}]
    expect(subject.others.first.test).to eq("foo")
  end

  it "should automatically guess the association class if possible" do
    subject.association_example_others = [{test: "foo"}]
    expect(subject.association_example_others.first.test).to eq("foo")
  end

  it "should not reinstantiate objects if it's already been called" do
    subject.others = [AssociationExampleOther.new(test: "foo")]
    expect(AssociationExampleOther).to_not receive(:new)
    subject.others
  end

  it "should return correctly instantiated nested associations" do
    subject.others = [{nested: [{test: "foo"}]}]
    expect(subject.others.first.nested.first.test).to eq("foo")
  end

  it "should correctly work with deep nested associations" do
    finder = DeepNestedHasManyExample.find
    expect(finder.results.count).to eq(2)
  end
end

describe "Has One Associations" do
  let(:subject) {AssociationExampleBase.new}

  it "should return nil if it's nil" do
    subject.child = nil
    expect(subject.child).to be_nil
  end

  it "should return a list of the association class" do
    subject.child = {test: "foo"}
    expect(subject.child).to be_an(AssociationExampleOther)
  end

  it "should return correctly instantiated association classes" do
    subject.child = {test: "foo"}
    expect(subject.child.test).to eq("foo")
  end

  it "should automatically guess the association class if possible" do
    subject.association_example_other = {test: "foo"}
    expect(subject.association_example_other.test).to eq("foo")
  end

  it "should not reinstantiate objects if it's already been called" do
    subject.child = AssociationExampleOther.new(test: "foo")
    expect(AssociationExampleOther).to_not receive(:new)
    subject.child
  end

  it "should return correctly instantiated nested associations" do
    subject.child = {nested_child: {test: "foo"}}
    expect(subject.child.nested_child.test).to eq("foo")
  end
end

describe "whitelisted date fields" do
  context "no whitelist specified" do
    let(:subject) {AssociationExampleNested}

    it "should show whitelist as empty array" do
      expect(subject._date_fields).to eq([])
    end
  end

  context "whitelist specified" do
    let(:subject) {WhitelistedDateExample}

    it "should contain whitelisted field" do
      expect(subject._date_fields).to eq([:updated_at])
    end
  end

  context "multiple attributes whitelisted" do
    let(:subject) {WhitelistedDateMultipleExample}

    it "should contain all fields" do
      expect(subject._date_fields).to match_array([:updated_at, :created_at, :generated_at])
    end
  end
end
