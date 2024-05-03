require 'spec_helper'

class MonthExample < Flexirest::Base
  base_url "http://www.example.com"

  get :find, "/month/:id", fake:"{\"name\":\"january\"}"
end

class YearExample < Flexirest::Base
  base_url "http://www.example.com"

  get :find, "/year/:id", lazy: { months: MonthExample }, fake: "{\"months\": [\"http://www.example.com/months/1\"] }"
end

class CenturyExample < Flexirest::Base
  base_url "http://www.example.com"

  get :find, "century/:id"
end

class DecadeExample < Flexirest::Base
  base_url "http://www.example.com"

  get :find, "/decade/:id", lazy: { years: YearExample, century: CenturyExample }, fake: %Q{
    {
      "years": ["http://www.example.com/years/1"],
      "century": "http://www.example.com/century/1"
    }
  }
end


describe Flexirest::LazyAssociationLoader do
  let(:url1) { "http://www.example.com/some/url" }
  let(:url2) { "http://www.example.com/some/other" }
  let(:calling_object) { o = double("Object").as_null_object }
  let(:request) { Flexirest::Request.new({:method => :get, url:"http://api.example.com/v1/foo"}, calling_object) }

  it "should raise an exception if you initialize it with a value that is not a string, hash or array" do
    expect do
      Flexirest::LazyAssociationLoader.new(:person, OpenStruct.new, nil)
    end.to raise_error(Flexirest::InvalidLazyAssociationContentException)
  end

  it "should store a URL passed as a string to the new object during creation" do
    loader = Flexirest::LazyAssociationLoader.new(:person, url1, nil)
    expect(loader.instance_variable_get(:@url)).to eq(url1)
  end

  it "should store a URL from a hash passed to the new object during creation" do
    loader = Flexirest::LazyAssociationLoader.new(:person, {"url" => url1}, nil)
    expect(loader.instance_variable_get(:@url)).to eq(url1)
  end

  it "should store a list of URLs from an array passed to the new object during creation" do
    loader = Flexirest::LazyAssociationLoader.new(:person, [url1, url2], nil)
    array = loader.instance_variable_get(:@subloaders)
    expect(array[0].instance_variable_get(:@url)).to eq(url1)
    expect(array[1].instance_variable_get(:@url)).to eq(url2)
    expect(array[2]).to be_nil
  end

  it "should store a hash of URLs from a hash passed to the new object during creation" do
    loader = Flexirest::LazyAssociationLoader.new(:person, {"main" => url1, "thumb" => url2}, request)
    expect(loader.main.instance_variable_get(:@url)).to eq(url1)
    expect(loader.thumb.instance_variable_get(:@url)).to eq(url2)
    expect(loader.size).to eq(2)
  end

  it "should still be able to iterate over a hash of URLs from a hash passed to the new object during creation" do
    loader = Flexirest::LazyAssociationLoader.new(:person, {"main" => url1, "thumb" => url2}, request)
    output = []
    loader.each do |k, v|
      output << v.instance_variable_get(:@url)
    end
    expect(output.size).to eq(2)
    expect(output[0]).to eq(url1)
    expect(output[1]).to eq(url2)
    expect(output[2]).to be_nil
  end

  it "should be able to list the keys from a hash passed to the new object during creation" do
    loader = Flexirest::LazyAssociationLoader.new(:person, {"main" => url1, "thumb" => url2}, request)
    expect(loader.keys[0]).to eq(:main)
    expect(loader.keys[1]).to eq(:thumb)
    expect(loader.keys.size).to eq(2)
  end

  it "should report the size of a list of stored URLs" do
    loader = Flexirest::LazyAssociationLoader.new(:person, [url1, url2], nil)
    expect(loader.size).to eq(2)
  end

  it "should respond to each and iterate through the list of stored URLs" do
    loader = Flexirest::LazyAssociationLoader.new(:person, [url1, url2], nil)
    output = []
    loader.each do |o|
      output << o.instance_variable_get(:@url)
    end
    expect(output.size).to eq(2)
    expect(output[0]).to eq(url1)
    expect(output[1]).to eq(url2)
    expect(output[2]).to be_nil
  end

  it "should return a LazyAssociationLoader for each stored URL in a list" do
    loader = Flexirest::LazyAssociationLoader.new(:person, [url1, url2], nil)
    output = []
    loader.each do |o|
      expect(o).to be_an_instance_of(Flexirest::LazyAssociationLoader)
    end
  end

  it "should make the request for a URL if it's accessed" do
    method_data = {options:{url:"foo"}}
    request = double("Request").as_null_object
    allow(request).to receive(:method).and_return(method_data)
    expect(request).to receive(:object).with(any_args).and_return(Array.new)
    expect(request).to receive(:call).with(any_args).and_return("")
    expect(Flexirest::Request).to receive(:new).with(any_args).and_return(request)
    loader = Flexirest::LazyAssociationLoader.new(:person, url1, request)
    loader.length
  end

  it "should proxy methods to the underlying object if the request has been made" do
    loader = Flexirest::LazyAssociationLoader.new(:person, url1, request)
    object = double("Object")
    expect(object).to receive(:length).and_return(1)
    loader.instance_variable_set(:@object, object)
    expect(loader.length).to eq(1)
  end

  it "should be able to iterate underlying object if it's an array" do
    loader = Flexirest::LazyAssociationLoader.new(:person, url1, request)
    expect_any_instance_of(Flexirest::Request).to receive(:call).with(any_args).and_return([1,2,3])
    test = []
    loader.each do |item|
      test << item
    end
    expect(test).to eq([1,2,3])
  end

  it "should be able to return the size of the underlying object if it's an array" do
    loader = Flexirest::LazyAssociationLoader.new(:person, url1, request)
    expect_any_instance_of(Flexirest::Request).to receive(:call).with(any_args).and_return([1,2,3])
    expect(loader.size).to eq(3)
  end

  it "should use the class specified in the 'lazy' declaration to parse the response rather than the class of the object the lazy loader is attached to" do
    association = YearExample.find(1)
    expect(association.months.instance_variable_get('@request').instance_variable_get('@object').class).to eq(MonthExample)
  end

  context "has multiple associations" do
    it "should correctly map each association name to the class specified for that association in the 'lazy' declaration " do
      association = DecadeExample.find(1)
      expect(association.years.instance_variable_get('@request').instance_variable_get('@object').class).to eq(YearExample)
      expect(association.century.instance_variable_get('@request').instance_variable_get('@object').class).to eq(CenturyExample)
    end
  end

end
