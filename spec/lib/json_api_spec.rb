require 'spec_helper'

class JsonAPIAssociationExampleOther < Flexirest::Base
end

class JsonAPIOneDataExample < Flexirest::Base
  has_many :others, JsonAPIAssociationExampleOther
  hash = {
    data: { id: 1, type: "example", attributes: { item: "item one" }, relationships: { "others": { data: [ { id: 1, type: "other" }, { id: 2, type: "other" } ] } } },
    included: [ { id: 1, type: "other", attributes: { item: "item two" } }, { id: 2, type: "other", attributes: { item: "item three" } } ]
  }
  get :find, "/iterate", fake: hash.to_json, fake_content_type: "application/vnd.api+json"
end

class JsonAPIMoreDataExample < Flexirest::Base
  has_many :others, JsonAPIAssociationExampleOther
  hash = {
    data: [
      { id: 1, type: "example", attributes: { item: "item one" }, relationships: { "others": { data: [ { id: 1, type: "other" }, { id: 2, type: "other" } ] } } },
      { id: 2, type: "example", attributes: { item: "item four" }, relationships: { "others": { data: [ { id: 2, type: "other" } ] } } }
    ],
    included: [ { id: 1, type: "other", attributes: { item: "item two" } }, { id: 2, type: "other", attributes: { item: "item three" } } ]
  }
  get :find, "/iterate", fake: hash.to_json, fake_content_type: "application/vnd.api+json"
end

class JsonAPIOneRelationshipExample < Flexirest::Base
  has_one :other, JsonAPIAssociationExampleOther
  hash = {
    data: { id: 1, type: "example", attributes: { item: "item one" }, relationships: { "other": { data: { id: 1, type: "other" } } } },
    included: [ { id: 1, type: "other", attributes: { item: "item two" } } ]
  }
  get :find, "/iterate", fake: hash.to_json, fake_content_type: "application/vnd.api+json"
end

class JsonAPILazyOtherExample < Flexirest::Base
  base_url "http://www.example.com"
  hash = { data: { id: 1, type: "other", attributes: { item: "item two" } } }
  get :find, "/other", fake: hash.to_json, fake_content_type: "application/vnd.api+json"
end

class JsonAPILazyLoadingExample < Flexirest::Base
  base_url "http://www.example.com"
  hash = {
    data: { id: 1, type: "example", attributes: { item: "item one" }, relationships: { "other": { links: { self: "http://www.example.com/relations/other", related: "http://www.example.com/other" } } } }
  }
  get :find, "/iterate", lazy: { other: JsonAPILazyOtherExample }, fake: hash.to_json, fake_content_type: "application/vnd.api+json"
end

describe "JSON API" do
  let(:subject1) { JsonAPIOneDataExample.new }
  let(:subject2) { JsonAPIMoreDataExample.new }
  let(:subject3) { JsonAPIOneRelationshipExample.new }
  let(:subject4) { JsonAPILazyLoadingExample.new }

  context "responses" do
    it "should return the data object if the response contains only one data instance" do
      expect(subject1.find).to be_a(JsonAPIOneDataExample)
    end

    it "should return a Flexirest::ResultIterator if the response contains more than one data instance" do
      expect(subject2.find).to be_a(Flexirest::ResultIterator)
    end
  end

  context "attributes" do
    it "should return the attributes as part of the data instance" do
      expect(subject1.find.item).to_not be_nil
    end

    it "should return the association's attributes as part of the association instance" do
      expect(subject3.find.other.item).to_not be_nil
    end
  end

  context "associations" do
    it "should retrieve the resource's associations via its relationships object" do
      expect(subject1.find.others.size).to eq(2)
    end

    it "should retrieve the response object if the relationship type is singular" do
      expect(subject3.find.other).to be_a(JsonAPIAssociationExampleOther)
    end

    it "should retrieve a Flexirest::ResultIterator if the relationship type is plural" do
      expect(subject1.find.others).to be_a(Flexirest::ResultIterator)
    end
  end

  context "lazy loading" do
    it "should retrieve the resource by loading the url from the links object" do
      expect(subject4.find.other).to be_a(Flexirest::LazyAssociationLoader)
      expect(subject4.find.other.id).to_not be_nil
      expect(subject4.find.other.item).to_not be_nil
    end
  end
end
