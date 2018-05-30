require 'spec_helper'

class EmptyExample < Flexirest::BaseWithoutValidation
  whiny_missing true
end

class TranslatorExample
  def self.all(object)
    ret = {}
    ret["first_name"] = object["name"]
    ret
  end
end

class AlteringClientExample < Flexirest::BaseWithoutValidation
  translator TranslatorExample
  base_url "http://www.example.com"

  get :all, "/all", fake:"{\"name\":\"Billy\"}"
  get :list, "/list", fake:"{\"name\":\"Billy\", \"country\":\"United Kingdom\"}"
  get :iterate, "/iterate", fake:"{\"name\":\"Billy\", \"country\":\"United Kingdom\"}"
  get :find, "/find/:id"
end

class RecordResponseExample < Flexirest::BaseWithoutValidation
  base_url "http://www.example.com"

  record_response do |url, response|
    raise Exception.new("#{url}|#{response.body}")
  end

  get :all, "/all"
end

class NonHostnameBaseUrlExample < Flexirest::BaseWithoutValidation
  base_url "http://www.example.com/v1/"
  get :all, "/all"
end

class InstanceMethodExample < Flexirest::BaseWithoutValidation
  base_url "http://www.example.com/v1/"
  get :all, "/all"
end

class WhitelistedDateExample < Flexirest::BaseWithoutValidation
  parse_date :updated_at
end


describe Flexirest::BaseWithoutValidation do
  it 'should instantiate a new descendant' do
    expect{EmptyExample.new}.to_not raise_error
  end

  it "should not instantiate a new base class" do
    expect{Flexirest::Base.new}.to raise_error(Exception)
  end

  it "should save attributes passed in constructor" do
    client = EmptyExample.new(test: "Something")
    expect(client._attributes[:test]).to be_a(String)
  end

  it "should allow attribute reading using missing method names" do
    client = EmptyExample.new(test: "Something")
    expect(client.test).to eq("Something")
  end

  it "should allow attribute reading using [] array notation" do
    client = EmptyExample.new(test: "Something")
    expect(client["test"]).to eq("Something")
  end

  it "allows iteration over attributes using each" do
    client = AlteringClientExample.iterate
    expect(client).to be_respond_to(:each)
    keys = []
    values = []
    client.each do |key, value|
      keys << key ; values << value
    end
    expect(keys).to eq(%w{name country}.map(&:to_sym))
    expect(values).to eq(["Billy", "United Kingdom"])
  end

  it "should automatically parse ISO 8601 format date and time" do
    t = Time.now
    client = EmptyExample.new(test: t.iso8601)
    expect(client["test"]).to be_an_instance_of(DateTime)
    expect(client["test"].to_s).to eq(t.to_datetime.to_s)
  end

  it "should automatically parse ISO 8601 format date and time with milliseconds" do
    t = Time.now
    client = EmptyExample.new(test: t.iso8601(3))
    expect(client["test"]).to be_an_instance_of(DateTime)
    expect(client["test"].to_s).to eq(t.to_datetime.to_s)
  end

  it "should automatically parse ISO 8601 format dates" do
    d = Date.today
    client = EmptyExample.new(test: d.iso8601)
    expect(client["test"]).to be_an_instance_of(Date)
    expect(client["test"]).to eq(d)
  end

  it "should automatically parse date/time strings regardless if the date portion has no delimiters" do
    client = EmptyExample.new(test: "20151230T09:48:50-05:00")
    expect(client["test"]).to be_an_instance_of(DateTime)
  end

  it "should allow strings of 4 digits and not intepret them as dates" do
    client = EmptyExample.new(test: "2015")
    expect(client["test"]).to be_an_instance_of(String)
  end

  it "should allow strings of 8 digits and not intepret them as dates" do
    client = EmptyExample.new(test: "1266129")
    expect(client["test"]).to be_an_instance_of(String)
  end

  it "should store attributes set using missing method names and mark them as dirty" do
    client = EmptyExample.new()
    client.test = "Something"
    expect(client.test.to_s).to eq("Something")
    expect(client).to be_dirty
  end

  it "should store attribute set using []= array notation and mark them as dirty" do
    client = EmptyExample.new()
    client["test"] = "Something"
    expect(client["test"].to_s).to eq("Something")
    expect(client).to be_dirty
  end

  it "should track changed attributes and provide access to previous values (similar to ActiveRecord/Mongoid)" do
    client = EmptyExample.new()
    client["test"] = "Something"

    client._clean! # force a clean state so we can proceed with tests

    expect(client).to_not be_dirty # clean state should have set in (dirty?)
    expect(client).to_not be_changed # clean state should have set in (changed?)
    expect(client["test"].to_s).to eq("Something") # verify attribute value persists

    client["test"] = "SomethingElse" # change the attribute value
    expect(client["test"].to_s).to eq("SomethingElse") # most current set value should be returned
    expect(client).to be_dirty # an attribute was changed, so the entire object is dirty
    expect(client).to be_changed # an attribute was changed, so the entire object is changed
    expect(client.changed).to be_a(Array) # the list of changed attributes should be an Array
    expect(client.changed).to eq([:test]) # the list of changed attributes should provide the name of the changed attribute
    expect(client.changes).to be_a(Hash) # changes are returned as a hash
    expect(client.changes).to eq({test: ["Something", "SomethingElse"]}) # changes include [saved,unsaved] values, keyed by attribute name
    expect(client.test_was).to eq("Something") # dynamic *_was notation provides original value

    client["test"] = "SomethingElseAgain" # change the attribute value again
    expect(client.test_was).to eq("Something") # dynamic *_was notation provides original value (from most recent save/load, not most recent change)
    expect(client.changes).to eq({test: ["Something", "SomethingElseAgain"]}) # changes include [saved,unsaved] values, keyed by attribute name

    # resets the test attribute back to the original value
    expect( client.reset_test! ).to eq(["Something", "SomethingElseAgain"]) # reseting an attribute returns the previous pending changeset
    expect(client).to_not be_dirty # reseting an attribute should makeit not dirty again
  end

  it "should overwrite attributes already set and mark them as dirty" do
    client = EmptyExample.new(hello: "World")
    client._clean!
    expect(client).to_not be_dirty

    client.hello = "Everybody"
    expect(client).to be_dirty
  end

  it 'should respond_to? attributes defined in the response' do
    client = EmptyExample.new(hello: "World")
    expect(client.respond_to?(:hello)).to be_truthy
    expect(client.respond_to?(:world)).to be_falsey
  end

  it "should save the base URL for the API server" do
    class BaseExample < Flexirest::Base
      base_url "https://www.example.com/api/v1"
    end
    expect(BaseExample.base_url).to eq("https://www.example.com/api/v1")
  end

  it "should allow changing the base_url while running" do
    class OutsideBaseExample < Flexirest::Base ; end

    Flexirest::Base.base_url = "https://www.example.com/api/v1"
    expect(OutsideBaseExample.base_url).to eq("https://www.example.com/api/v1")

    Flexirest::Base.base_url = "https://www.example.com/api/v2"
    expect(OutsideBaseExample.base_url).to eq("https://www.example.com/api/v2")
  end

  it "should include the Mapping module" do
    expect(EmptyExample).to respond_to(:_calls)
    expect(EmptyExample).to_not respond_to(:_non_existant)
  end

  it "should be able to easily clean all attributes" do
    client = EmptyExample.new(hello:"World", goodbye:"Everyone")
    expect(client).to be_dirty
    client._clean!
    expect(client).to_not be_dirty
  end

  it "should not overly pollute the instance method namespace to reduce chances of clashing (<13 instance methods)" do
    instance_methods = EmptyExample.instance_methods - Object.methods
    instance_methods = instance_methods - instance_methods.grep(/^_/)
    expect(instance_methods.size).to be < 13
  end

  it "should raise an exception for missing attributes if whiny_missing is enabled" do
    expect{EmptyExample.new.first_name}.to raise_error(Flexirest::NoAttributeException)
  end

  it "should be able to lazy instantiate an object from a prefixed lazy_ method call" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with('/find/1', anything).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
    example = AlteringClientExample.lazy_find(1)
    expect(example).to be_an_instance_of(Flexirest::LazyLoader)
    expect(example.first_name).to eq("Billy")
  end

  it "should be able to lazy instantiate an object from a prefixed lazy_ method call from an instance" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with('/find/1', anything).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
    example = AlteringClientExample.new.lazy_find(1)
    expect(example).to be_an_instance_of(Flexirest::LazyLoader)
    expect(example.first_name).to eq("Billy")
  end

  context "#inspect output" do
    it "displays a nice version" do
      object = EmptyExample.new(id: 1, name: "John Smith")
      expect(object.inspect).to match(/#<EmptyExample id: 1, name: "John Smith"/)
    end

    it "shows dirty attributes as a list of names at the end" do
      object = EmptyExample.new(id: 1, name: "John Smith")
      expect(object.inspect).to match(/#<EmptyExample id: 1, name: "John Smith" \(unsaved: id, name\)/)
    end

    it "doesn't show an empty list of dirty attributes" do
      object = EmptyExample.new(id: 1, name: "John Smith")
      object.instance_variable_set(:@dirty_attributes, Set.new)
      expect(object.inspect).to_not match(/\(unsaved: id, name\)/)
    end

    it "shows dates in a nice format" do
      object = EmptyExample.new(dob: Time.new(2015, 01, 02, 03, 04, 05))
      expect(object.inspect).to match(/#<EmptyExample dob: "2015\-01\-02 03:04:05"/)
    end

    it "shows the etag if one is set" do
      object = EmptyExample.new(id: 1)
      object.instance_variable_set(:@_etag, "sample_etag")
      expect(object.inspect).to match(/#<EmptyExample id: 1, ETag: sample_etag/)
    end

    it "shows the HTTP status code if one is set" do
      object = EmptyExample.new(id: 1)
      object.instance_variable_set(:@_status, 200)
      expect(object.inspect).to match(/#<EmptyExample id: 1, Status: 200/)
    end

    it "shows [uninitialized] for new objects" do
      object = EmptyExample.new
      expect(object.inspect).to match(/#<EmptyExample \[uninitialized\]/)
    end

  end

  context "accepts a Translator to reformat JSON" do
    it "should log a deprecation warning when using a translator" do
      expect(Flexirest::Logger).to receive(:warn) do |message|
        expect(message).to start_with("DEPRECATION")
      end
      Proc.new do
        class DummyExample < Flexirest::Base
          translator TranslatorExample
        end
      end.call
    end

    it "should call Translator#method when calling the mapped method if it responds to it" do
      expect(TranslatorExample).to receive(:all).with(an_instance_of(Hash)).and_return({})
      AlteringClientExample.all
    end

    it "should not raise errors when calling Translator#method if it does not respond to it" do
      expect {AlteringClientExample.list}.to_not raise_error
    end

    it "should translate JSON returned through the Translator" do
      ret = AlteringClientExample.all
      expect(ret.first_name).to eq("Billy")
      expect(ret.name).to be_nil
    end

    it "should return original JSON for items that aren't handled by the Translator" do
      ret = AlteringClientExample.list
      expect(ret.name).to eq("Billy")
      expect(ret.first_name).to be_nil
    end
  end

  context "directly call a URL, rather than via a mapped method" do
    it "should be able to directly call a URL" do
      expect_any_instance_of(Flexirest::Request).to receive(:do_request).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      EmptyExample._request("http://api.example.com/")
    end

    it "allows already encoded bodies" do
      Flexirest::ConnectionManager.reset!
      connection = double("Connection")
      allow(connection).to receive(:base_url).and_return("http://api.example.com")
      expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://api.example.com/").and_return(connection)
      expect(connection).
        to receive(:post).
        with("http://api.example.com/", "{\"test\":\"value\"}",an_instance_of(Hash)).
        and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:200)))
      EmptyExample._request("http://api.example.com/", :post, {test: "value"}.to_json, request_body_type: :json)
    end

    it "passes headers" do
      stub_request(:get, "http://api.example.com/v1").
        with(headers: {'Accept'=>'application/hal+json, application/json;q=0.5', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection'=>'Keep-Alive', 'Content-Type'=>'application/x-www-form-urlencoded', 'X-Something'=>'foo/bar', 'User-Agent'=>/Flexirest\//}).
        to_return(status: 200, body: "", headers: {})
      EmptyExample._request("http://api.example.com/v1", :get, {}, {headers: {"X-Something" => "foo/bar"}})
    end

    it "passes headers if the response is unparsed" do
      stub_request(:get, "http://api.example.com/v1").
        with(headers: {'Accept'=>'application/hal+json, application/json;q=0.5', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection'=>'Keep-Alive', 'Content-Type'=>'application/x-www-form-urlencoded', 'X-Something'=>'foo/bar', 'User-Agent'=>/Flexirest\//}).
        to_return(status: 200, body: "", headers: {})
      EmptyExample._plain_request("http://api.example.com/v1", :get, {}, {headers: {"X-Something" => "foo/bar"}})
    end

    it "runs callbacks as usual" do
      expect_any_instance_of(Flexirest::Request).to receive(:do_request).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      expect(EmptyExample).to receive(:_callback_request).with(any_args).exactly(2).times
      EmptyExample._request("http://api.example.com/")
    end

    it "should make an HTTP request" do
      expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      EmptyExample._request("http://api.example.com/")
    end

    it "should make an HTTP request including the path in the base_url" do
      expect_any_instance_of(Flexirest::Connection).to receive(:get).with('/v1/all', anything).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      NonHostnameBaseUrlExample.all
    end

    it "should map the response from the directly called URL in the normal way" do
      expect_any_instance_of(Flexirest::Request).to receive(:do_request).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      example = EmptyExample._request("http://api.example.com/")
      expect(example.first_name).to eq("Billy")
    end

    it "should be able to pass the plain response from the directly called URL bypassing JSON loading" do
      response_body = "This is another non-JSON string"
      expect_any_instance_of(Flexirest::Connection).to receive(:post).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:response_body)))
      expect(EmptyExample._plain_request("http://api.example.com/", :post, {id:1234})).to eq(response_body)
    end

    it "should return a PlainResponse from the directly called URL bypassing JSON loading" do
      response_body = "This is another non-JSON string"
      expect_any_instance_of(Flexirest::Connection).to receive(:post).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:response_body)))
      expect(EmptyExample._plain_request("http://api.example.com/", :post, {id:1234})).to be_a(Flexirest::PlainResponse)
    end

    context "Simulating Faraday connection in_parallel" do
      it "should be able to pass the plain response from the directly called URL bypassing JSON loading" do
        response_body = "This is another non-JSON string"
        response = ::FaradayResponseMock.new(
          OpenStruct.new(status:200, response_headers:{}, body:response_body),
          false)
        expect_any_instance_of(Flexirest::Connection).to receive(:post).with(any_args).and_return(response)
        result = EmptyExample._plain_request("http://api.example.com/", :post, {id:1234})

        expect(result).to eq(nil)

        response.finish
        expect(result).to eq(response_body)
      end
    end

    it "should cache plain requests separately" do
      perform_caching = EmptyExample.perform_caching
      cache_store = EmptyExample.cache_store
      begin
        response = "This is a non-JSON string"
        other_response = "This is another non-JSON string"
        allow_any_instance_of(Flexirest::Connection).to receive(:get) do |instance, url, others|
          if url["/?test=1"]
            ::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:response))
          else
            ::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:other_response))
          end
        end
        EmptyExample.perform_caching = true
        EmptyExample.cache_store = TestCacheStore.new
        expect(EmptyExample._plain_request("http://api.example.com/?test=1")).to eq(response)
        expect(EmptyExample._plain_request("http://api.example.com/?test=2")).to eq(other_response)
      ensure
        EmptyExample.perform_caching = perform_caching
        EmptyExample.cache_store = cache_store
      end
    end

    it "should work with caching if instance methods are used" do
      perform_caching = InstanceMethodExample.perform_caching
      cache_store = InstanceMethodExample.cache_store
      begin
        response = "{\"id\": 1, \"name\":\"test\"}"
        allow_any_instance_of(Flexirest::Connection).to receive(:get).and_return(            ::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{"Etag" => "12345678", "Content-type" => "application/json"}, body:response)))
        e = InstanceMethodExample.new
        e.all(1)
        expect(e.id).to eq(1)
      ensure
        InstanceMethodExample.perform_caching = perform_caching
        InstanceMethodExample.cache_store = cache_store
      end
    end

    it "should be able to lazy load a direct URL request" do
      expect_any_instance_of(Flexirest::Request).to receive(:do_request).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      example = EmptyExample._lazy_request("http://api.example.com/")
      expect(example).to be_an_instance_of(Flexirest::LazyLoader)
      expect(example.first_name).to eq("Billy")
    end

    it "should be able to specify a method and parameters for the call" do
      expect_any_instance_of(Flexirest::Connection).to receive(:post).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      EmptyExample._request("http://api.example.com/", :post, {id:1234})
    end

    it "should be able to replace parameters in the URL for the call" do
      expect_any_instance_of(Flexirest::Connection).to receive(:post).with("http://api.example.com/1234", "", any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      EmptyExample._request("http://api.example.com/:id", :post, {id:1234})
    end

    it "should be able to use mapped methods to create a request to pass in to _lazy_request" do
      expect_any_instance_of(Flexirest::Connection).to receive(:get).with('/find/1', anything).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"{\"first_name\":\"Billy\"}")))
      request = AlteringClientExample._request_for(:find, id: 1)
      example = AlteringClientExample._lazy_request(request)
      expect(example.first_name).to eq("Billy")
    end
  end

  context "Recording a response" do
    it "calls back to the record_response callback with the url and response body" do
      expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:"Hello world")))
      expect{RecordResponseExample.all}.to raise_error(Exception, "/all|Hello world")
    end
  end

  context "JSON output" do
    let(:student1) { EmptyExample.new(name:"John Smith", age:31) }
    let(:student2) { EmptyExample.new(name:"Bob Brown", age:29) }
    let(:location) { EmptyExample.new(place:"Room 1408") }
    let(:lazy) { Laz }
    let(:object) { EmptyExample.new(name:"Programming 101", location:location, students:[student1, student2]) }
    let(:json_parsed_object) { MultiJson.load(object.to_json) }

    it "should be able to export to valid json" do
      expect(object.to_json).to_not be_blank
      expect{MultiJson.load(object.to_json)}.to_not raise_error
    end

    it "should not be using Object's #to_json method" do
      expect(json_parsed_object["dirty_attributes"]).to be_nil
    end

    it "should recursively convert nested objects" do
      expect(json_parsed_object["location"]["place"]).to eq(location.place)
    end

    it "should include arrayed objects" do
      expect(json_parsed_object["students"]).to be_an_instance_of(Array)
      expect(json_parsed_object["students"].size).to eq(2)
      expect(json_parsed_object["students"].first["name"]).to eq(student1.name)
      expect(json_parsed_object["students"].second["name"]).to eq(student2.name)
    end

    it "should set integers as a native JSON type" do
      expect(json_parsed_object["students"].first["age"]).to eq(student1.age)
      expect(json_parsed_object["students"].second["age"]).to eq(student2.age)
    end
  end

  describe "instantiating object" do
    context "no whitelist specified" do
      it "should convert dates automatically" do
        client = EmptyExample.new(test: Time.now.iso8601)
        expect(client["test"]).to be_an_instance_of(DateTime)
      end
    end

    context "whitelist specified" do
      it "should only convert specified dates" do
        time = Time.now.iso8601
        client = WhitelistedDateExample.new(updated_at: time, created_at: time)
        expect(client["updated_at"]).to be_an_instance_of(DateTime)
        expect(client["created_at"]).to be_an_instance_of(String)
      end
    end
  end

end
