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
end

describe "Has One Associations" do
  let(:subject) {AssociationExampleBase.new}

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
