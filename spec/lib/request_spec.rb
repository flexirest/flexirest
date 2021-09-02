require 'spec_helper'

describe Flexirest::Request do
  before :each do
    class ExampleOtherClient < Flexirest::Base ; end
    class ExampleSingleClient < Flexirest::Base ; end
    class ExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      request_body_type :form_encoded
      api_auth_credentials('id123', 'secret123')

      before_request do |name, request|
        if request.method[:name] == :headers
          request.headers["X-My-Header"] = "myvalue"
        end
      end

      before_request do |name, request|
        if request.method[:name] == :cancel_callback
          false
        end
      end

      after_request do |name, response|
        if name == :change
          response.body = "{\"test\": 1}"
        end
      end

      get :all, "/", has_many: {expenses: ExampleOtherClient}
      get :flat, "/", params_encoder: :flat
      get :array, "/johnny", array: [:likes, :dislikes]
      get :babies, "/babies", has_many: {children: ExampleOtherClient}
      get :basket, "/basket", array: [:options]
      get :dates, "/dates", array: [:dates]
      get :single_association, "/single", has_one: {single: ExampleSingleClient}, has_many: {children: ExampleOtherClient}
      get :headers, "/headers"
      get :cancel_callback, "/cancel-callback"
      put :headers_default, "/headers_default"
      put :headers_json, "/headers_json", request_body_type: :json
      get :find, "/:id", required: [:id]
      get :find_cat, "/:id/cat"
      get :fruits, "/fruits"
      get :uncached, "/uncached", skip_caching: true
      get :change, "/change"
      get :plain, "/plain/:id", plain: true
      post :create, "/create", rubify_names: true
      post :test_encoding, "/encoding", request_body_type: :json
      post :testing_no_content_headers, "/no-content"
      put :update, "/put/:id"
      put :wrapped, "/put/:id", wrap_root: "example"
      put :conversion, "/put/:id", parse_fields: [:converted]
      put :conversion_child, "/put/:id", parse_fields: [:converted_child]
      delete :remove, "/remove/:id"
      delete :remove_body, "/remove/:id", send_delete_body: true
      get :hal, "/hal", fake:"{\"_links\":{\"child\": {\"href\": \"/child/1\"}, \"other\": {\"href\": \"/other/1\"}, \"cars\":[{\"href\": \"/car/1\", \"name\":\"car1\"}, {\"href\": \"/car/2\", \"name\":\"car2\"}, {\"href\": \"/car/not-embed\", \"name\":\"car_not_embed\"} ], \"lazy\": {\"href\": \"/lazy/load\"}, \"invalid\": [{\"href\": \"/invalid/1\"}]}, \"_embedded\":{\"other\":{\"name\":\"Jane\"},\"child\":{\"name\":\"Billy\"}, \"cars\":[{\"_links\": {\"self\": {\"href\": \"/car/1\"} }, \"make\": \"Bugatti\", \"model\": \"Veyron\"}, {\"_links\": {\"self\": {\"href\": \"/car/2\"} }, \"make\": \"Ferrari\", \"model\": \"F458 Italia\"} ], \"invalid\": [{\"present\":true, \"_links\": {} } ] } }", has_many:{other:ExampleOtherClient}
      get :fake_object, "/fake", fake:"{\"result\":true, \"list\":[1,2,3,{\"test\":true}], \"child\":{\"grandchild\":{\"test\":true}}}"
      get :fake_proc_object, "/fake", fake:->(request) { "{\"result\":#{request.get_params[:id]}}" }
      get :fake_method, "/fake", fake: :generate_fake_data
      get :fake_array, "/fake", fake:"[1,2,3,{\"test\":true},null]"
      get :fake_proc_array, "/fake", fake:->(request) { "[{\"result\":#{request.get_params[:id]}},null]" }
      get :defaults, "/defaults", defaults:{overwrite:"no", persist:"yes"}
      get :requires, "/requires", requires:[:name, :age]
      patch :only_changed_1, "/changed1", only_changed: true
      patch :only_changed_2, "/changed2", only_changed: [:debug1, :debug2]
      patch :only_changed_3, "/changed3", only_changed: { debug1: false, debug2: true }

      def generate_fake_data
        "{\"result\":true, \"list\":[1,2,3,{\"test\":true}], \"child\":{\"grandchild\":{\"test\":true}}}"
      end
    end

    class ExampleLoadBalancedClient < Flexirest::Base
      base_url ["http://api1.example.com", "http://api2.example.com"]
      get :all, "/", has_many: {expenses: ExampleOtherClient}
    end

    class AuthenticatedExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      username "john"
      password "smith"
      get :all, "/"
    end

    class AuthenticatedBasicHeaderExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      username "john"
      password "smith"
      basic_auth_method :header
      get :all, "/"
    end

    class AuthenticatedBasicHeaderExampleClientChildClass < AuthenticatedBasicHeaderExampleClient
      get :child_method, "/"
    end

    class AuthenticatedBasicUrlExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      username "john"
      password "smith"
      basic_auth_method :url
      get :all, "/"
    end

    class AuthenticatedProcExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      username Proc.new { |obj| obj ? "bill-#{obj.id}" : "bill" }
      password do |obj|
        if obj
          "jones-#{obj.id}"
        else
          "jones"
        end
      end
      get :all, "/"
    end

    class ApiAuthProcExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      api_auth_credentials( Proc.new { |obj| obj ? "key-#{obj.id}" : "key" },
                            Proc.new { |obj| obj ? "secret-#{obj.id}" : "secret" }
                          )
      get :all, "/"
    end

    class ProcDefaultExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      get :all, "/", defaults: (Proc.new do |params|
        reference = params.delete(:reference)
        {
          id: "id-#{reference}"
        }
      end)
    end

    class RetryingExampleClient < Flexirest::Base
      base_url "http://www.example.com"

      after_request :handle_retries
      after_request :inner_call

      def self.reset_retries
        @retries = 0
      end

      def self.incr_retries
        @retries ||= 0
        @retries += 1
      end

      def self.retries
        @retries
      end

      def handle_retries(name, response)
        if name == :do_me_twice
          self.class.incr_retries
          return :retry
        end
      end

      def inner_call(name, response)
        if name == :first_call
          self.class.incr_retries
          self.second_call
          raise Flexirest::CallbackRetryRequestException.new
        end
      end

      get :do_me_twice, "/do_me_twice"
      get :first_call, "/first_call"
      get :second_call, "/second_call"
    end

    class LazyLoadedExampleClient < ExampleClient
      base_url "http://www.example.com"
      lazy_load!
      get :fake_object, "/fake", fake:"{\"result\":true, \"list\":[1,2,3,{\"test\":true}], \"child\":{\"grandchild\":{\"test\":true}}}"
      get :fake_array, "/fake", fake:"[1,2,3,{\"test\":true},{\"child\":{\"grandchild\":{\"test\":true}}}]"
      get :lazy_test, "/does-not-matter", fake:"{\"people\":[\"http://www.example.com/some/url\"]}", lazy: [:people]
    end

    class VerboseExampleClient < ExampleClient
      base_url "http://www.example.com"
      verbose!
      get :all, "/all"
      post :create, "/create"
    end

    class CallbackBodyExampleClient < ExampleClient
      base_url "http://www.example.com"
      before_request do |name, request|
        request.body = MultiJson.dump(request.post_params)
      end

      post :save, "/save"
    end

    class IgnoredRootExampleClient < ExampleClient
      get :root, "/root", ignore_root: "feed", fake: %Q{
        {
          "feed": {
            "title": "Example Feed"
          }
        }
      }
    end

    class IgnoredRootWithUnexpectedResponseExampleClient < ExampleClient
      get :root, "/root", ignore_root: "feed", fake: %Q{
        {
          "error": {
            "message": "Example Error"
          }
        }
      }
    end

    class IgnoredMultiLevelRootExampleClient < ExampleClient
      get :multi_level_root, "/multi-level-root", ignore_root: [:response, "data", "object"], fake: %Q{
        {
          "response": {
            "data": {
              "object": {
                "title": "Example Multi Level Feed"
              }
            }
          }
        }
      }
    end

    class LocalIgnoredRootExampleClient < ExampleClient
      ignore_root "feed"

      get :root, "/root", fake: %Q{
        {
          "feed": {
            "title": "Example Feed"
          }
        }
      }
    end

    class LocalIgnoredMultiLevelRootExampleClient < ExampleClient
      ignore_root [:response, "data", "object"]

      get :multi_level_root, "/multi-level-root", fake: %Q{
        {
          "response": {
            "data": {
              "object": {
                "title": "Example Multi Level Feed"
              }
            }
          }
        }
      }
    end

    class BaseIgnoredRootExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      ignore_root "feed"
    end

    class GlobalIgnoredRootExampleClient < BaseIgnoredRootExampleClient
      get :root, "/root", fake: %Q{
        {
          "feed": {
            "title": "Example Feed"
          }
        }
      }
    end

    class OverrideGlobalIgnoredRootForFileExampleClient < BaseIgnoredRootExampleClient
      ignore_root "data"

      get :root, "/root", fake: %Q{
        {
          "data": {
            "title": "Example Feed"
          }
        }
      }
    end

    class OverrideGlobalIgnoredRootForRequestExampleClient < BaseIgnoredRootExampleClient
      get :root, "/root", ignore_root: "data", fake: %Q{
        {
          "data": {
            "title": "Example Feed"
          }
        }
      }
    end

    class BaseWrappedRootExampleClient < Flexirest::Base
      base_url "http://www.example.com"
      wrap_root "base_data"
    end

    class GlobalWrappedRootExampleClient < BaseWrappedRootExampleClient
      put :wrapped, "/put/:id"
    end

    class OverrideGlobalWrappedRootForFileExampleClient < BaseWrappedRootExampleClient
      wrap_root "class_specific_data"
      put :wrapped, "/put/:id"
    end

    class OverrideGlobalWrappedRootForRequestExampleClient < BaseWrappedRootExampleClient
      put :wrapped, "/put/:id", wrap_root: "request_specific_data"
    end

    class WhitelistedDateClient < Flexirest::Base
      base_url "http://www.example.com"
      put :conversion, "/put/:id"
      put :conversion_child, "/put/:id"
      parse_date :converted, :converted_child
    end

    allow_any_instance_of(Flexirest::Request).to receive(:read_cached_response)
  end

  it "should get an HTTP connection when called" do
    connection = double(Flexirest::Connection).as_null_object
    expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://www.example.com").and_return(connection)
    expect(connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.all
  end

  it "should get an HTTP connection from one of the servers when called if multiple are specified" do
    connection = double(Flexirest::Connection).as_null_object
    expect(connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    servers = []
    # TODO: this next test is potentially flakey, if over 10 runs of []#sample it doesn't return both variants, but it's so unlikely...
    30.times do
      expect(Flexirest::ConnectionManager).to receive(:get_connection) do |arg|
        servers << arg
        connection
      end
      ExampleLoadBalancedClient.all
    end
    expect(servers.uniq.count).to eq(2)
  end

  it "should use the URL method for Basic HTTP Auth when no basic_auth_method is set" do
    mocked_response = ::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{}))

    connection = double(Flexirest::Connection).as_null_object
    expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://john:smith@www.example.com").and_return(connection)
    expect(connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(mocked_response)
    AuthenticatedExampleClient.all
  end

  it "should use the headers method for Basic auth when basic_auth_method is set to :header" do
    mocked_response = ::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{}))
    headers_including_auth = hash_including({ "Authorization" => "Basic am9objpzbWl0aA==" })

    connection = double(Flexirest::Connection).as_null_object
    expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://www.example.com").and_return(connection)
    expect(connection).to receive(:get).with("/", hash_including(headers: headers_including_auth)).and_return(mocked_response)
    AuthenticatedBasicHeaderExampleClient.all
  end

  it "should raise an error if Basic HTTP method is not :header or :url" do
    expect do
      AuthenticatedExampleClient.class_eval do
        basic_auth_method :some_invalid_value
      end
    end.to raise_error(RuntimeError, "Invalid basic_auth_method :some_invalid_value. Valid methods are :url (default) and :header.")
  end

  it "should use the setting set on the parent class" do
    mocked_response = ::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{}))
    headers_including_auth = hash_including({ "Authorization" => "Basic am9objpzbWl0aA==" })

    connection = double(Flexirest::Connection).as_null_object
    expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://www.example.com").and_return(connection)
    expect(connection).to receive(:get).with("/", hash_including(headers: headers_including_auth)).and_return(mocked_response)
    AuthenticatedBasicHeaderExampleClientChildClass.child_method
  end

  it "should use the URL method for Basic auth when basic_auth_method is set to :url (and not include Authorization header)" do
    mocked_response = ::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{}))
    headers_not_including_auth = hash_excluding("Authorization")

    connection = double(Flexirest::Connection).as_null_object
    expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://john:smith@www.example.com").and_return(connection)
    expect(connection).to receive(:get).with("/", headers: headers_not_including_auth).and_return(mocked_response)
    AuthenticatedBasicUrlExampleClient.all
  end

  it "should get an HTTP connection with basic authentication using procs when called in a class context" do
    connection = double(Flexirest::Connection).as_null_object
    expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://bill:jones@www.example.com").and_return(connection)
    expect(connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    AuthenticatedProcExampleClient.all
  end

  it "should get an HTTP connection with basic authentication using procs when called in an object context" do
    connection = double(Flexirest::Connection).as_null_object
    expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://bill-1:jones-1@www.example.com").and_return(connection)
    expect(connection).to receive(:get).with("/?id=1", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    obj = AuthenticatedProcExampleClient.new(id: 1)
    obj.all
  end

  it "should get an HTTP connection with API authentication using procs when called in a class context" do
    header_expectation = {headers: {"Accept"=>"application/hal+json, application/json;q=0.5", "Content-Type"=>"application/x-www-form-urlencoded; charset=utf-8"}, api_auth: {api_auth_access_id: "key", api_auth_secret_key: "secret", api_auth_options: {}}}
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/", header_expectation).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ApiAuthProcExampleClient.all
  end

  it "should get an HTTP connection with API authentication using procs when called in an object context" do
    header_expectation = {headers: {"Accept"=>"application/hal+json, application/json;q=0.5", "Content-Type"=>"application/x-www-form-urlencoded; charset=utf-8"}, api_auth: {api_auth_access_id: "key-1", api_auth_secret_key: "secret-1", api_auth_options: {}}}
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/?id=1", header_expectation).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    obj = ApiAuthProcExampleClient.new(id: 1)
    obj.all
  end

  it "should get an HTTP connection when called and call get on it" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.all
  end

  it "should get an HTTP connection when called and call delete on it" do
    expect_any_instance_of(Flexirest::Connection).to receive(:delete).with("/remove/1", "", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.remove(id:1)
  end

  it "should get an HTTP connection when called and call delete with a body if send_delete_body is specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:delete).with("/remove/1", "something=else", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.remove_body(id:1, something: "else")
  end

  it "should get an HTTP connection when called and call delete without a body if send_delete_body is not specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:delete).with("/remove/1", "", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.remove(id:1, something: "else")
  end

  it "should work with faraday response objects" do
    response = Faraday::Response.new
    allow(response).to receive(:body).and_return({}.to_json)
    expect_any_instance_of(Flexirest::Connection).to receive(:get).and_return(response)
    expect { ExampleClient.all }.to_not raise_error
  end

  it "should pass through get parameters" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/?debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.all debug:true
  end

  it "should correctly serialise array parameters" do
    # name: ["john", "bill"] should become name[]=john&name[]=bill (but URL-safe so %5B%5D)
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/?name%5B%5D=john&name%5B%5D=bill", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.all name: ["john", "bill"]
  end

  it "should pass through get parameters, using defaults specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/defaults?overwrite=yes&persist=yes", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.defaults overwrite:"yes"
  end

  it "should pass through get parameters, calling the proc if one is specified for defaults" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/?id=id-123456", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ProcDefaultExampleClient.all reference:"123456"
  end

  it "should ensure any required parameters are specified" do
    expect_any_instance_of(Flexirest::Connection).to_not receive(:get)
    expect{ExampleClient.requires}.to raise_error(Flexirest::MissingParametersException)
    expect{ExampleClient.requires name: "John"}.to raise_error(Flexirest::MissingParametersException)
    expect{ExampleClient.requires age: 21}.to raise_error(Flexirest::MissingParametersException)
    expect{ExampleClient.requires name: nil, age: nil}.to raise_error(Flexirest::MissingParametersException)
  end

  it "should ensure any URL parameters are implicitly required and error if not specified" do
    expect_any_instance_of(Flexirest::Connection).to_not receive(:get)
    expect{ExampleClient.find_cat}.to raise_error(Flexirest::MissingParametersException)
  end

  it "should ensure any URL parameters are implicitly required and make the request if specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    expect{ExampleClient.find_cat(1)}.to_not raise_error
  end

  it "should makes the request if all required parameters are specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    expect{ExampleClient.requires name: "John", age: 21}.not_to raise_error
  end

  it "should makes the request if all required parameters are specified, even if boolean" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    expect{ExampleClient.requires name: true, age: false}.not_to raise_error
  end

  it "should pass through url parameters" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/1234", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.find id:1234
  end

  it "should pass URL-encode URL parameters" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/foo+bar", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.find id:"foo bar"
  end

  it "should pass URL-encode URL parameters including slashes" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/foo%2Fbar", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.find id:"foo/bar"
  end

  it "should accept an integer as the only parameter and use it as id" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/1234", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.find(1234)
  end

  it "should accept a string as the only parameter and use it as id" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/1234", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.find("1234")
  end

  it "should pass through url parameters and get parameters" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/1234?debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.find id:1234, debug:true
  end

  it "should pass through url parameters and put parameters" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.update id:1234, debug:true
  end

  it "should pass through url parameters and get parameters" do
    expect_any_instance_of(Flexirest::Connection).to_not receive(:get)
    ExampleClient.cancel_callback
  end

  it "should pass through 'array type' get parameters" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/?include%5B%5D=your&include%5B%5D=friends", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.all include: [:your,:friends]
  end

  it "should pass through 'array type' get parameters using the same parameter name if a flat param_encoder is chosen" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/?include=your&include=friends", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.flat include: [:your,:friends]
  end

  it "should encode the body in a form-encoded format by default" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true&test=foo", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.update id:1234, debug:true, test:'foo'
  end

  it "should encode the body in a form-encoded format by default" do
    body = "--FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY\r\n" +
      "Content-Disposition: form-data; name=\"debug\"\r\n" +
      "\r\n" +
      "true\r\n" +
      "--FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY\r\n"+
      "Content-Disposition: form-data; name=\"arrayz[]\"\r\n"+
      "\r\n"+
      "1\r\n"+
      "--FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY\r\n"+
      "Content-Disposition: form-data; name=\"arrayz[]\"\r\n"+
      "\r\n"+
      "2\r\n"+
      "--FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY\r\n"+
      "Content-Disposition: form-data; name=\"hazh[something]\"\r\n"+
      "\r\n"+
      "bar\r\n"+
      "--FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY\r\n" +
      "Content-Disposition: form-data; name=\"test\"\r\n" +
      "\r\n" +
      "foo\r\n" +
      "--FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY\r\n" +
      "Content-Disposition: form-data; name=\"file\"; filename=\"#{File.dirname(__FILE__)}/../../spec/samples/file.txt\"\r\n" +
      "Content-Type: text/plain\r\n" +
      "\r\n" +
      "The quick brown fox jumps over the lazy dog\n\r\n" +
      "--FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY--"
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with(
      "/put/1234", body, hash_including(headers: hash_including("Content-Type"=>"multipart/form-data; boundary=FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY"))
    ).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.request_body_type :form_multipart
    ExampleClient.update id:1234, debug:true, arrayz: [1, 2], hazh: {something: "bar"}, test:'foo', file: File.open("#{File.dirname(__FILE__)}/../../spec/samples/file.txt")
  end

  it "should encode the body in a JSON format if specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q({"debug":true,"test":"foo"}), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.request_body_type :json
    ExampleClient.update id:1234, debug:true, test:'foo'
  end

  it "should encode the body wrapped in a root element in a JSON format if specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q({"example":{"debug":true,"test":"foo"}}), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.request_body_type :json
    ExampleClient.wrapped id:1234, debug:true, test:'foo'
  end

  it "should pass the body untouched if plain format is specified on the class" do
    header_expectation = {headers: {"Accept"=>"application/hal+json, application/json;q=0.5", "Content-Type"=>"text/plain"}, api_auth: {api_auth_access_id: "id123", api_auth_secret_key: "secret123", api_auth_options: {}}}
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug:true|test:'foo'", header_expectation).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.request_body_type :plain
    ExampleClient.update id:1234, body: "debug:true|test:'foo'"
  end

  it "should use the content type specified if plain format is specified on the class" do
    header_expectation = {headers: {"Accept"=>"application/hal+json, application/json;q=0.5", "Content-Type"=>"application/flexirest"}, api_auth: {api_auth_access_id: "id123", api_auth_secret_key: "secret123", api_auth_options: {}}}
    expect_any_instance_of(Flexirest::Connection).to receive(:put).
      with("/put/1234", "debug:true|test:'foo'", header_expectation).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.request_body_type :plain
    ExampleClient.update id:1234, body: "debug:true|test:'foo'", content_type: "application/flexirest"
  end

  it "should wrap elements if specified, in form-encoded format" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q(example%5Bdebug%5D=true&example%5Btest%5D=foo), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.wrapped id:1234, debug:true, test:'foo'
  end

  it "should not pass through an encoded empty body parameter" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/1234", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.request_body_type :json
    ExampleClient.find id:1234
  end

  it "allows forcing a request_body_type per request" do
    expect_any_instance_of(Flexirest::Connection).to receive(:post).with("/encoding", %q({"id":1234,"test":"something"}), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    ExampleClient.request_body_type :form_encoded # Should be ignored and the per_method :json used
    ExampleClient.test_encoding id:1234, test: "something"
  end

  it "should pass through custom headers" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get){ |connection, path, options|
      expect(path).to eq('/headers')
      expect(options[:headers]).to include("X-My-Header" => "myvalue")
    }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.headers
  end

  it "should set request header with content-type for default" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put){ |connection, path, data, options|
      expect(path).to eq('/headers_default')
      expect(data).to eq('')
      expect(options[:headers]).to include("Content-Type" => "application/x-www-form-urlencoded")
    }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.headers_default
  end

  it "should set request header with content-type for JSON" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put){ |connection, path, data, options|
      expect(path).to eq('/headers_json')
      expect(data).to eq('{}')
      expect(options[:headers]).to include("Content-Type" => "application/json; charset=utf-8")
    }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
    ExampleClient.headers_json
  end

  it "should parse JSON to give a nice object" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true, \"list\":[1,2,3,{\"test\":true}], \"created_at\":\"2012-03-04T01:02:03Z\", \"child\":{\"grandchild\":{\"test\":true}}}", response_headers:{})))
    object = ExampleClient.update id:1234, debug:true
    expect(object.result).to eq(true)
    expect(object.list.first).to eq(1)
    expect(object.list.last.test).to eq(true)
    expect(object.created_at).to be_an_instance_of(DateTime)
    expect(object.child.grandchild.test).to eq(true)
  end

  it "should not convert date times in JSON if automatic parsing is disabled" do
    begin
      Flexirest::Base.disable_automatic_date_parsing = true
      expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"created_at\":\"2012-03-04T01:02:03Z\"}", response_headers:{})))
      object = ExampleClient.update id:1234, debug:true
      expect(object.created_at).to be_an_instance_of(String)
    ensure
      Flexirest::Base.disable_automatic_date_parsing = false
    end
  end

  it "should only convert date times in JSON if specified when converted is root property" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"converted\":\"2012-03-04T01:02:03Z\", \"not_converted\":\"2012-03-04T01:02:03Z\"}", response_headers:{})))
    object = ExampleClient.conversion id:1234, debug:true
    expect(object.converted).to be_an_instance_of(DateTime)
    expect(object.not_converted).to be_an_instance_of(String)
  end

  it "should only convert date times in JSON if specified when converted is child property" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"not_converted\":\"2012-03-04T01:02:03Z\", \"child\":{\"converted_child\":\"2012-03-04T01:02:03Z\"}}", response_headers:{})))
    object = ExampleClient.conversion_child id:1234, debug:true
    expect(object.child.converted_child).to be_an_instance_of(DateTime)
    expect(object.not_converted).to be_an_instance_of(String)
  end

  it "should convert date times in JSON if root property is whitelisted" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"converted\":\"2012-03-04T01:02:03Z\", \"not_converted\":\"2012-03-04T01:02:03Z\"}", response_headers:{})))
    object = WhitelistedDateClient.conversion id:1234, debug:true
    expect(object.converted).to be_an_instance_of(DateTime)
    expect(object.not_converted).to be_an_instance_of(String)
  end

  it "should convert date times in JSON if child property is whitelisted" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"not_converted\":\"2012-03-04T01:02:03Z\", \"child\":{\"converted_child\":\"2012-03-04T01:02:03Z\"}}", response_headers:{})))
    object = WhitelistedDateClient.conversion_child id:1234, debug:true
    expect(object.child.converted_child).to be_an_instance_of(DateTime)
    expect(object.not_converted).to be_an_instance_of(String)
  end

  it "should convert date times in JSON from a result iterator response" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/dates", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"[\"2012-03-04T01:02:03Z\", \"2012-03-04T01:02:03Z\"]", response_headers:{})))
    object = ExampleClient.dates
    expect(object).to be_a(Flexirest::ResultIterator)
    expect(object.items).to be_a(Array)
    expect(object.first).to be_an_instance_of(DateTime)
  end

  it "should convert date times in JSON even in a pure array" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/dates", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"dates\":[\"2012-03-04T01:02:03Z\", \"2012-03-04T01:02:03Z\"]}", response_headers:{})))
    object = ExampleClient.dates
    expect(object).to be_a(ExampleClient)
    expect(object.dates).to be_a(Array)
    expect(object.dates.first).to be_an_instance_of(DateTime)
  end

  it "should parse JSON object and return a nice object for faked responses" do
    object = ExampleClient.fake_object id:1234, debug:true
    expect(object.result).to eq(true)
    expect(object.list.first).to eq(1)
    expect(object.list.last.test).to eq(true)
    expect(object.child.grandchild.test).to eq(true)
  end

  it "should parse JSON object from a fake response generated by a proc" do
    object = ExampleClient.fake_proc_object id:1234
    expect(object.result).to eq(1234)
  end

  it "should parse JSON object from a fake response generated by method defined as a symbol" do
    object = ExampleClient.fake_method id:1234
    expect(object.result).to eq(true)
  end

  it "should parse JSON array and return a nice result iterator for faked responses" do
    object = ExampleClient.fake_array debug:true
    expect(object).to be_instance_of(Flexirest::ResultIterator)
    expect(object.size).to eq(5)
    expect(object.first).to eq(1)
    expect(object.last).to eq(nil)
    expect(object[3]).to be_instance_of(ExampleClient)
    expect(object[3].test).to eq(true)
    expect(object._status).to eq(200)
  end

  it "should parse JSON array from a fake response generated by a proc" do
    object = ExampleClient.fake_proc_array id:1234
    expect(object).to be_instance_of(Flexirest::ResultIterator)
    expect(object.size).to eq(2)
    expect(object.first).to be_instance_of(ExampleClient)
    expect(object.first.result).to eq(1234)
    expect(object.last).to eq(nil)
    expect(object._status).to eq(200)
  end

  it "should not parse JSON from a plain request" do
    response_body = "This is another non-JSON string"
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:response_body)))
    expect(ExampleClient.plain(id:1234)).to eq(response_body)
  end

  it "should return a PlainResponse from a plain request" do
    response_body = "This is another non-JSON string"
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body:response_body)))
    expect(ExampleClient.plain(id:1234)).to be_a(Flexirest::PlainResponse)
  end

  it "should return true from 204 with empty bodies" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:204, response_headers:{}, body: nil)))
    expect(ExampleClient.all).to be_truthy
  end

  it "should return true from 202 with empty bodies" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:202, response_headers:{}, body: nil)))
    expect(ExampleClient.all).to be_truthy
  end

  it "should return true from 200 with empty bodies" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{}, body: nil)))
    expect(ExampleClient.all).to be_truthy
  end

  it "should return true from 200 with empty bodies even if they don't have a correct content type" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(::FaradayResponseMock.new(OpenStruct.new(status:200, response_headers:{"Content-Type" => "text/plain"}, body: nil)))
    expect(ExampleClient.all).to be_truthy
  end

  it "should return a lazy loader object if lazy loading is enabled for JSON object" do
    object = LazyLoadedExampleClient.fake_object id:1234, debug:true
    expect(object).to be_an_instance_of(Flexirest::LazyLoader)
  end

  it "should proxy through nice object for lazy loaded responses from JSON object" do
    object = LazyLoadedExampleClient.fake_object id:1234, debug:true
    expect(object.instance_variable_get(:@result)).to be(nil)
    expect(object.result).to eq(true) # method call the attribute received in response and never the instance attribute of the LazyLoader class
    expect(object.instance_variable_get(:@result)).to be_a(LazyLoadedExampleClient)
    expect(object.list.first).to eq(1)
    expect(object.list.last.test).to eq(true)
    expect(object.child.grandchild.test).to eq(true)
  end

  it "should return a lazy loader object if lazy loading is enabled for JSON array" do
    object = LazyLoadedExampleClient.fake_array debug:true
    expect(object).to be_an_instance_of(Flexirest::LazyLoader)
  end

  it "should proxy through nice result iterator for lazy loaded responses from JSON array" do
    object = LazyLoadedExampleClient.fake_array debug:true
    expect(object.instance_variable_get(:@result)).to be(nil)
    expect(object.items).to be_a(Array)
    expect(object.instance_variable_get(:@result)).to be_a(Flexirest::ResultIterator)
    expect(object.first).to eq(1)
    expect(object[3].test).to eq(true)
    expect(object.last.child.grandchild.test).to eq(true)
  end

  it "should return a LazyAssociationLoader for lazy loaded properties" do
    object = LazyLoadedExampleClient.lazy_test
    expect(object.people.size).to eq(1)
    expect(object.people).to be_an_instance_of(Flexirest::LazyAssociationLoader)
  end

  it "should log faked responses" do
    allow(Flexirest::Logger).to receive(:debug)
    expect(Flexirest::Logger).to receive(:debug).with(/Faked response found/)
    ExampleClient.fake_object id:1234, debug:true
  end

  it "should parse an array within JSON to be a result iterator" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"[{\"first_name\":\"Johnny\"}, {\"first_name\":\"Billy\"}]", status:200, response_headers:{})))
    object = ExampleClient.update id:1234, debug:true
    expect(object).to be_instance_of(Flexirest::ResultIterator)
    expect(object.first.first_name).to eq("Johnny")
    expect(object[1].first_name).to eq("Billy")
    expect(object._status).to eq(200)
  end

  it "should parse a nested array within JSON to be a result iterator" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"[[{}, {\"first_name\":\"Johnny\"}, {\"first_name\":\"Billy\"}]]", status:200, response_headers:{})))
    object = ExampleClient.update id:1234, debug:true
    expect(object).to be_instance_of(Flexirest::ResultIterator)
    expect(object[0][1].first_name).to eq("Johnny")
    expect(object[0][2].first_name).to eq("Billy")
    expect(object._status).to eq(200)
  end

  it "should parse an attribute to be an array if attribute included in array option" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/johnny", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"likes\":[\"donuts\", \"bacon\"], \"dislikes\":[\"politicians\", \"lawyers\", \"taxes\"]}", status:200, response_headers:{})))
    object = ExampleClient.array
    expect(object.likes).to be_instance_of(Array)
    expect(object.likes.size).to eq(2)
    expect(object.likes[0]).to eq("donuts")
    expect(object.likes[1]).to eq("bacon")
    expect(object.dislikes).to be_instance_of(Array)
    expect(object.dislikes.size).to eq(3)
    expect(object.dislikes[0]).to eq("politicians")
    expect(object.dislikes[1]).to eq("lawyers")
    expect(object.dislikes[2]).to eq("taxes")
    #TODO
  end

  it "should parse an attribute to be an array if attribute included in a nested array" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/johnny", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"nested_array\":[[{\"likes\":[\"donuts\", \"bacon\"], \"dislikes\":[\"politicians\", \"lawyers\", \"taxes\"]}]]}", status:200, response_headers:{})))
    object = ExampleClient.array
    nested_array = object.nested_array[0][0]
    expect(nested_array.likes).to be_instance_of(Array)
    expect(nested_array.likes.size).to eq(2)
    expect(nested_array.likes[0]).to eq("donuts")
    expect(nested_array.likes[1]).to eq("bacon")
    expect(nested_array.dislikes).to be_instance_of(Array)
    expect(nested_array.dislikes.size).to eq(3)
    expect(nested_array.dislikes[0]).to eq("politicians")
    expect(nested_array.dislikes[1]).to eq("lawyers")
    expect(nested_array.dislikes[2]).to eq("taxes")
    #TODO - Pasted from the Test above
  end

  it "should parse an attribute to be either a result iterator or an array and containing simple values like integers" do
      expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/basket", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"products\":[101, 55, 37], \"options\":[854, 225, 772]}", status:200, response_headers:{})))
      object = ExampleClient.basket
      expect(object).to be_instance_of(ExampleClient)
      expect(object.products).to be_a(Flexirest::ResultIterator)
      expect(object.products.size).to eq(3)
      expect(object.products.first).to eq(101)
      expect(object.products[1]).to eq(55)
      expect(object.products.last).to eq(37)
      expect(object.options).to be_a(Array)
      expect(object.options.size).to eq(3)
      expect(object.options.first).to eq(854)
      expect(object.options[1]).to eq(225)
      expect(object.options.last).to eq(772)
      expect(object._status).to eq(200)
      #TODO - Pasted from the Test above
    end

  it "should parse the response to be a result iterator and containing simple values like strings" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/fruits", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"[\"apple\", \"banana\", \"pear\", \"watermelon\"]", status:200, response_headers:{})))
    object = ExampleClient.fruits
    expect(object).to be_instance_of(Flexirest::ResultIterator)
    expect(object.first).to eq('apple')
    expect(object[1]).to eq('banana')
    expect(object.last).to eq('watermelon')
    expect(object._status).to eq(200)
    #TODO - Pasted from the Test above
  end

  it "should only send changed attributes if only_changed:true" do
    expect_any_instance_of(Flexirest::Connection).to receive(:patch).with("/changed1", "debug=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"[{\"first_name\":\"Johnny\"}, {\"first_name\":\"Billy\"}, {\"debug\":\"true\"}]", status:200, response_headers:{})))
    object = ExampleClient.new
    object.bad_debug = true
    object._clean!
    object.debug = true
    object.only_changed_1
  end

  it "should only send changed attributes within the :only_changed array if :only_changed is an array" do
    expect_any_instance_of(Flexirest::Connection).to receive(:patch).with("/changed2", "debug2=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"[{\"first_name\":\"Johnny\"}, {\"first_name\":\"Billy\"}, {\"debug\":\"true\"}]", status:200, response_headers:{})))
    object = ExampleClient.new
    object.bad_debug1 = true
    object.debug1 = true
    object._clean!
    object.bad_debug2 = true
    object.debug2 = true
    object.only_changed_2
  end

  it "should only send changed attributes marked true within the :only_changed hash when :only_changed is a hash" do
    expect_any_instance_of(Flexirest::Connection).to receive(:patch).with("/changed3", "debug1=false&debug2=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"[{\"first_name\":\"Johnny\"}, {\"first_name\":\"Billy\"}, {\"debug\":\"true\"}]", status:200, response_headers:{})))
    object = ExampleClient.new
    object.bad_debug1 = true
    object.debug1 = true
    object._clean!
    object.bad_debug2 = true
    object.debug1 = false
    object.debug2 = true
    object.only_changed_3
  end

  it "should always send changed attributes marked false within the :only_changed hash when :only_changed is an hash" do
    expect_any_instance_of(Flexirest::Connection).to receive(:patch).with("/changed3", "debug1=true", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"[{\"first_name\":\"Johnny\"}, {\"first_name\":\"Billy\"}, {\"debug\":\"true\"}]", status:200, response_headers:{})))
    object = ExampleClient.new
    object.bad_debug1 = true
    object.debug1 = true
    object._clean!
    object.bad_debug2 = true
    object.only_changed_3
  end

  it "should instantiate other classes using has_many when required to do so" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"expenses\":[{\"amount\":1}, {\"amount\":2}]}", status:200, response_headers:{})))
    object = ExampleClient.all
    expect(object.expenses.first).to be_instance_of(ExampleOtherClient)
  end

  it "should instantiate other classes using has_many even if nested off the root" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/babies", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"children\":{\"eldest\":[{\"name\":\"Billy\"}]}}", status:200, response_headers:{})))
    object = ExampleClient.babies
    expect(object.children.eldest.first).to be_instance_of(ExampleOtherClient)
  end

  it "should instantiate other classes using has_one when required to do so" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/single", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"single\":{\"name\":\"Billy\"}}", status:200, response_headers:{})))
    object = ExampleClient.single_association
    expect(object.single).to be_instance_of(ExampleSingleClient)
  end

  it "should instantiate other classes using has_one even if nested off the root" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/single", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"children\":[{\"single\":{\"name\":\"Billy\"}}, {\"single\":{\"name\":\"Sharon\"}}]}", status:200, response_headers:{})))
    object = ExampleClient.single_association
    expect(object.children.first.single).to be_instance_of(ExampleSingleClient)
  end

  it "should assign new attributes to the existing object if possible" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{})))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    object.create
    expect(object.first_name).to eq("John")
    expect(object.should_disappear).to eq(nil)
    expect(object.id).to eq(1234)
  end

  it "should rubify attribute names" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"firstName\":\"John\", \"OtherProperty\":1234}", response_headers:{})))
    object = ExampleClient.create
    expect(object.first_name).to eq("John")
    expect(object.other_property).to eq(1234)
  end

  it "should expose etag if available" do
    response = ::FaradayResponseMock.new(OpenStruct.new(body: "{}", response_headers: {"ETag" => "123456"}, status: 200))
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/123", an_instance_of(Hash)).and_return(response)
    object = ExampleClient.find(123)
    expect(object._etag).to eq("123456")
  end

  it "shouldn't expose the etag header if skip_caching is enabled" do
    response = ::FaradayResponseMock.new(OpenStruct.new(body: "{}", response_headers: {"ETag" => "123456"}, status: 200))
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/uncached", an_instance_of(Hash)).and_return(response)
    object = ExampleClient.uncached
    expect(object._etag).to_not eq("123456")
  end

  it "shouldn't send the etag header if skip_caching is enabled" do
    cached_response = Flexirest::CachedResponse.new(status:200, result:"", response_headers: {})
    cached_response.etag = "123456"
    expect(ExampleClient).to receive(:read_cached_response).and_return(cached_response)

    response = ::FaradayResponseMock.new(OpenStruct.new(body: "{}", response_headers: {"ETag" => "123456"}, status: 200))
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/uncached", {
      api_auth: {
        api_auth_access_id: "id123",
        api_auth_options: {},
        api_auth_secret_key: "secret123"
      },
      headers: {
        "Accept"=>"application/hal+json, application/json;q=0.5",
        "Content-Type"=>"application/x-www-form-urlencoded; charset=utf-8"
      }
    }).and_return(response)

    expect(ExampleClient).to_not receive(:write_cached_response)
    object = ExampleClient.uncached
  end

  it "should expose all headers" do
    response = ::FaradayResponseMock.new(OpenStruct.new(body: "{}", response_headers: {"X-Test-Header" => "true"}, status: 200))
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/123", an_instance_of(Hash)).and_return(response)
    object = ExampleClient.find(123)
    expect(object._headers["X-Test-Header"]).to eq("true")
  end

  it "should expose all headers on collection" do
    response = ::FaradayResponseMock.new(OpenStruct.new(body: "[{}]", response_headers: {"X-Test-Header" => "true"}, status: 200))
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/123", an_instance_of(Hash)).and_return(response)
    object = ExampleClient.find(123)
    expect(object._headers["X-Test-Header"]).to eq("true")
  end

  it "should clearly pass through 200 status responses" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:200)))
    expect(Flexirest::Logger).to receive(:info).with(%r'Requesting http://www.example.com/create')
    allow(Flexirest::Logger).to receive(:debug)
    expect(Flexirest::Logger).to receive(:debug).at_least(1).times.with(%r'(Response received \d+ bytes|Trying to read from cache)')

    object = ExampleClient.new(first_name:"John", should_disappear:true)
    object.create
    expect(object._status).to eq(200)
  end

  it "should debug log 200 responses" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:200)))
    expect(Flexirest::Logger).to receive(:info).with(%r'Requesting http://www.example.com/create')
    allow(Flexirest::Logger).to receive(:debug)
    expect(Flexirest::Logger).to receive(:debug).at_least(1).times.with(%r'(Response received \d+ bytes|Trying to read from cache)')

    object = ExampleClient.new(first_name:"John", should_disappear:true)
    object.create
  end

  it "should verbose debug the with the right http verb" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:200)))
    expect(Flexirest::Logger).to receive(:debug).with(/ POST /)
    allow(Flexirest::Logger).to receive(:debug)

    object = VerboseExampleClient.new(first_name:"John", should_disappear:true)
    object.create
  end

  it "should verbose log if enabled" do
    connection = double(Flexirest::Connection).as_null_object
    expect(Flexirest::ConnectionManager).to receive(:get_connection).and_return(connection)
    expect(connection).to receive(:get).with("/all", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{"Content-Type" => "application/json", "Connection" => "close"})))
    expect(Flexirest::Logger).to receive(:debug).with("Flexirest Verbose Log:")
    expect(Flexirest::Logger).to receive(:debug).with(/ >> /).at_least(:twice)
    expect(Flexirest::Logger).to receive(:debug).with(/ << /).at_least(:twice)
    allow(Flexirest::Logger).to receive(:debug).with(any_args)
    VerboseExampleClient.all
  end

  it "should return the headers still for 202 responses" do
    fake_location = "https://foo.example.com/123"
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/no-content", "", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"", response_headers:{"location" => fake_location}, status:202)))
    response = ExampleClient.testing_no_content_headers
    expect(response._headers["location"]).to eq(fake_location)
  end

  it "should raise an unauthorised exception for 401 errors" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:401)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue Flexirest::HTTPUnauthorisedClientException => e
      e
    end
    expect(e).to be_instance_of(Flexirest::HTTPUnauthorisedClientException)
    expect(e.status).to eq(401)
    expect(e.result.first_name).to eq("John")
  end

  it "should raise a forbidden client exception for 403 errors" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:403)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue Flexirest::HTTPForbiddenClientException => e
      e
    end
    expect(e).to be_instance_of(Flexirest::HTTPForbiddenClientException)
    expect(e.status).to eq(403)
    expect(e.result.first_name).to eq("John")
  end

  it "should raise a not found client exception for 404 errors" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:404)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue Flexirest::HTTPNotFoundClientException => e
      e
    end
    expect(e).to be_instance_of(Flexirest::HTTPNotFoundClientException)
    expect(e.status).to eq(404)
    expect(e.result.first_name).to eq("John")
  end

  it "should raise a client exceptions for 4xx errors" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:409)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue Flexirest::HTTPClientException => e
      e
    end
    expect(e.to_s).to eq("The POST to '/create' returned a 409 status, which raised a Flexirest::HTTPConflictClientException with a body of: {\"first_name\":\"John\", \"id\":1234}")
    expect(e).to be_a(Flexirest::HTTPClientException)
    expect(e).to be_instance_of(Flexirest::HTTPConflictClientException)
    expect(e.status).to eq(409)
    expect(e.result.first_name).to eq("John")
  end

  it "should raise a server exception for 5xx errors" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:500)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue Flexirest::HTTPServerException => e
      e
    end
    expect(e).to be_instance_of(Flexirest::HTTPInternalServerException)
    expect(e.status).to eq(500)
    expect(e.result.first_name).to eq("John")
  end

  it "should return a useful message for errors" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:500)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue Flexirest::HTTPServerException => e
      e
    end
    expect(e.message).to eq(%q{The POST to '/create' returned a 500 status, which raised a Flexirest::HTTPInternalServerException with a body of: \{"first_name":"John", "id":1234\}})
  end

  it "should raise a parse exception for invalid JSON returns" do
    error_content = "<h1>500 Server Error</h1>"
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:error_content, response_headers:{'Content-Type' => 'text/html'}, status:500)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue => e
      e
    end
    expect(e).to be_instance_of(Flexirest::HTTPInternalServerException)
    expect(e.status).to eq(500)
    expect(e.result).to eq(error_content)
  end

  it "should raise a bad request exception for 400 response status" do
    error_content = "<h1>400 Bad Request</h1>"
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:error_content, response_headers:{'Content-Type' => 'text/html'}, status:400)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue => e
      e
    end
    expect(e).to be_instance_of(Flexirest::HTTPBadRequestClientException)
    expect(e.status).to eq(400)
    expect(e.result).to eq(error_content)
  end

  it "should raise response parse exception for invalid JSON content" do
    message_content = "Success"
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:message_content, response_headers:{'Content-Type' => 'application/json'}, status:200)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue => e
      e
    end
    expect(e).to be_instance_of(Flexirest::ResponseParseException)
    expect(e.status).to eq(200)
    expect(e.body).to eq(message_content)
  end

  it "should raise response parse exception for 200 response status and non json content type" do
    error_content = "<h1>malformed json</h1>"
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:error_content, response_headers:{'Content-Type' => 'text/html'}, status:200)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue => e
      e
    end
    expect(e).to be_instance_of(Flexirest::ResponseParseException)
    expect(e.status).to eq(200)
    expect(e.body).to eq(error_content)
  end

  it "should not override the attributes of the existing object on error response status" do
    expect_any_instance_of(Flexirest::Connection).
      to receive(:post).
      with("/create", "first_name=John&should_disappear=true", an_instance_of(Hash)).
      and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"errors": ["validation": "error in validation"]}', response_headers:{'Content-Type' => 'text/html'}, status:400)))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    begin
      object.create
    rescue => e
      e
    end
    expect(e).to be_instance_of(Flexirest::HTTPBadRequestClientException)
    expect(e.status).to eq(400)
    expect(object.first_name).to eq 'John'
    expect(object.errors).to eq(nil)
  end

  it "should raise an exception if you try to pass in an unsupport method" do
    method = {method: :wiggle, url:"/"}
    class RequestFakeObject < Flexirest::Base
      base_url "http://www.example.com/"

      def request_body_type
        :form_encoded
      end

      def username ; end
      def password ; end
      def name ; end
      def _callback_request(*args) ; end
      def verbose ; false ; end
    end
    fake_object = RequestFakeObject.new
    request = Flexirest::Request.new(method, fake_object, {})
    allow(fake_object).to receive(:read_cached_response).and_return(nil)
    expect{request.call}.to raise_error(Flexirest::InvalidRequestException)
  end

  it "should send all object's attributes and params through class mapped methods" do
    expect_any_instance_of(Flexirest::Connection).to receive(:post).with("/create", "arg=2&prop=1", anything).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"expenses\":[{\"amount\":1}, {\"amount\":2}]}", status:200, response_headers:{})))
    client = ExampleClient.new(prop: "1")
    client.create(arg: "2")
  end

  it "should send all class mapped methods through _callback_request" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"expenses\":[{\"amount\":1}, {\"amount\":2}]}", status:200, response_headers:{})))
    expect(ExampleClient).to receive(:_callback_request).with(any_args).exactly(2).times
    ExampleClient.all
  end

  it "should send all instance mapped methods through _callback_request" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"expenses\":[{\"amount\":1}, {\"amount\":2}]}", status:200, response_headers:{})))
    expect(ExampleClient).to receive(:_callback_request).with(any_args).exactly(2).times
    e = ExampleClient.new
    e.all
  end

  it "should change the generated object if an after_request changes it" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/change", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"Johnny\", \"expenses\":[{\"amount\":1}, {\"amount\":2}]}", status:200, response_headers:{})))
    obj = ExampleClient.change
    expect(obj.test).to eq(1)
  end

  it "should retry if an after_request callback returns :retry" do
    stub_request(:get, "http://www.example.com/do_me_twice").
      to_return(status: 200, body: "", headers: {})
    RetryingExampleClient.reset_retries
    RetryingExampleClient.do_me_twice
    expect(RetryingExampleClient.retries).to eq(2)
  end

  it "should allow a second call and then retry if an after_request callback returns :retry" do
    stub_request(:get, "http://www.example.com/first_call").
      to_return(status: 200, body: "", headers: {})
    stub_request(:get, "http://www.example.com/second_call").
      to_return(status: 200, body: "", headers: {})
    RetryingExampleClient.reset_retries
    RetryingExampleClient.first_call
    expect(RetryingExampleClient.retries).to eq(2)
  end


  context "Direct URL requests" do
    class SameServerExampleClient < Flexirest::Base
      URL = "http://www.example.com/some/url"
      base_url "http://www.example.com/v1"
      get :same_server, "/does-not-matter", url:URL
    end

    class OtherServerExampleClient < Flexirest::Base
      URL = "http://other.example.com/some/url"
      base_url "http://www.example.com/v1"
      get :other_server, "/does-not-matter", url:URL
    end

    it "should allow requests directly to URLs" do
      Flexirest::ConnectionManager.reset!
      expect_any_instance_of(Flexirest::Connection).
        to receive(:get).
        with("/some/url", an_instance_of(Hash)).
        and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:200)))
      SameServerExampleClient.same_server
    end

    it "should allow requests directly to URLs even if to different URLs" do
      Flexirest::ConnectionManager.reset!
      connection = double("Connection")
      expect(connection).
        to receive(:get).
        with("/some/url", an_instance_of(Hash)).
        and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{}", response_headers:{}, status:304)))
      allow(connection).
        to receive(:base_url).
        and_return("http://other.example.com")
      expect(Flexirest::ConnectionManager).to receive(:find_connection_for_url).with(OtherServerExampleClient::URL).and_return(connection)
      OtherServerExampleClient.other_server
    end

    it "should allow requests to partial URLs using the current base_url" do
      Flexirest::ConnectionManager.reset!
      connection = double("Connection")
      allow(connection).to receive(:base_url).and_return("http://www.example.com")
      expect(Flexirest::ConnectionManager).to receive(:get_connection).with("http://www.example.com").and_return(connection)
      expect(connection).
        to receive(:get).
        with("/v1/people", an_instance_of(Hash)).
        and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}", response_headers:{}, status:200)))
      @obj = SameServerExampleClient._request('/people')
    end
  end

  # HAL is Hypermedia Application Language
  context "HAL" do
    let(:hal) { ExampleClient.hal }

    it "should request a HAL response or plain JSON" do
      expect_any_instance_of(Flexirest::Connection).to receive(:get){ |connection, path, options|
        expect(path).to eq('/headers')
        expect(options[:headers]).to include("Accept" => "application/hal+json, application/json;q=0.5")
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:'{"result":true}', response_headers:{})))
      ExampleClient.headers
    end

    it "should recognise a HAL response" do
      method = {method: :get, url:"/"}
      class RequestFakeObject
        def base_url
          "http://www.example.com/"
        end

        def name ; end
        def _callback_request(*args) ; end
      end
      fake_object = RequestFakeObject.new
      request = Flexirest::Request.new(method, fake_object, {})
      request.instance_variable_set(:@response, OpenStruct.new(response_headers:{"Content-Type" => "application/hal+json"}))
      expect(request.hal_response?).to be_truthy
      request.instance_variable_set(:@response, OpenStruct.new(response_headers:{"Content-Type" => "application/json"}))
      expect(request.hal_response?).to be_truthy
      request.instance_variable_set(:@response, OpenStruct.new(response_headers:{"Content-Type" => "text/plain"}))
      expect(request.hal_response?).to be_falsey
      request.instance_variable_set(:@response, OpenStruct.new(response_headers:{"Content-Type" => ["text/plain", "application/hal+json"]}))
      expect(request.hal_response?).to be_truthy
      request.instance_variable_set(:@response, OpenStruct.new(response_headers:{"Content-Type" => ["text/plain", "application/json"]}))
      expect(request.hal_response?).to be_truthy
      request.instance_variable_set(:@response, OpenStruct.new(response_headers:{"Content-Type" => ["text/plain"]}))
      expect(request.hal_response?).to be_falsey
    end

    it "should map _links in to the normal attributes" do
      expect(hal.child).to be_an_instance_of(ExampleClient)
      expect(hal.cars.size).to eq(3)
    end

    it "should be able to use other attributes of _links using _hal_attributes method with a key" do
      expect(hal.child).to be_an_instance_of(ExampleClient)
      expect(hal.cars[2]._hal_attributes("name")).to eq('car_not_embed')
    end

    it "should use _embedded responses instead of lazy loading if possible" do
      expect(hal.child.name).to eq("Billy")
      expect(hal.cars.first.make).to eq("Bugatti")
    end

    it "should instantiate other classes defined using has_many when using _embedded responses" do
      expect(hal.other).to be_an(ExampleOtherClient)
    end

    it "should convert invalid _embedded responses in to lazy loading on error" do
      expect(hal.invalid.first).to be_an_instance_of(Flexirest::LazyAssociationLoader)
    end

    it "should lazy load _links attributes if not embedded" do
      expect(hal.lazy).to be_an_instance_of(Flexirest::LazyAssociationLoader)
      expect(hal.lazy.instance_variable_get(:@url)).to eq("/lazy/load")
    end
  end

  it "replaces the body completely in a callback" do
    expect_any_instance_of(Flexirest::Connection).to receive(:post).with("/save", "{\"id\":1234,\"name\":\"john\"}", an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{}", response_headers:{})))
    CallbackBodyExampleClient.save id:1234, name:'john'
  end

  context 'Simulating Faraday connection in_parallel' do
    it 'should parse JSON and return a single object' do
      response = ::FaradayResponseMock.new(
        OpenStruct.new(body:"{\"result\":true, \"list\":[1,2,3,{\"test\":true}], \"created_at\":\"2012-03-04T01:02:03Z\", \"child\":{\"grandchild\":{\"test\":true}}}", response_headers:{}),
        false)
      expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(response)
      object = ExampleClient.update id:1234, debug:true

      expect(object).to eq(nil)

      response.finish
      expect(object.result).to eq(true)
      expect(object.list.first).to eq(1)
      expect(object.list.last.test).to eq(true)
      expect(object.created_at).to be_an_instance_of(DateTime)
      expect(object.child.grandchild.test).to eq(true)
    end

    it 'should parse an array within JSON and return a result iterator' do
      response = ::FaradayResponseMock.new(
        OpenStruct.new(body:"[{\"first_name\":\"Johnny\"}, {\"first_name\":\"Billy\"}]", status:200, response_headers:{}),
        false)
      expect_any_instance_of(Flexirest::Connection).to receive(:get).with("/", an_instance_of(Hash)).and_return(response)
      object = ExampleClient.all

      expect(object).to eq(nil)

      response.finish
      expect(object).to be_instance_of(Flexirest::ResultIterator)
      expect(object.first.first_name).to eq("Johnny")
      expect(object[1].first_name).to eq("Billy")
      expect(object._status).to eq(200)
      object.each do |item|
        expect(item).to_not be_nil
      end
    end

    it 'should return a RequestDelegator object to wrap the result' do
      response = ::FaradayResponseMock.new(
        OpenStruct.new(body:"{\"result\":true, \"list\":[1,2,3,{\"test\":true}], \"created_at\":\"2012-03-04T01:02:03Z\", \"child\":{\"grandchild\":{\"test\":true}}}", response_headers:{}),
        false)
      expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", "debug=true", an_instance_of(Hash)).and_return(response)
      object = ExampleClient.update id:1234, debug:true
      response.finish

      expect(object.class).to eq(ExampleClient)
      expect(object.kind_of?(ExampleClient)).to be_truthy
      expect(object.is_a?(ExampleClient)).to be_truthy
      expect(object._delegate?).to be_truthy
    end
  end

  it "should ignore a specified root element" do
    expect(IgnoredRootExampleClient.root.title).to eq("Example Feed")
  end

  it "should ignore an ignore_root parameter if the specified element is not in the response" do
    expect(IgnoredRootWithUnexpectedResponseExampleClient.root.error.message).to eq("Example Error")
  end

  it "should ignore a specified multi-level root element" do
    expect(IgnoredMultiLevelRootExampleClient.multi_level_root.title).to eq("Example Multi Level Feed")
  end

  it "should ignore a specified root element" do
    expect(LocalIgnoredRootExampleClient.root.title).to eq("Example Feed")
  end

  it "should ignore a specified multi-level root element" do
    expect(LocalIgnoredMultiLevelRootExampleClient.multi_level_root.title).to eq("Example Multi Level Feed")
  end

  it "should ignore a specified root element" do
    expect(GlobalIgnoredRootExampleClient.root.title).to eq("Example Feed")
  end

  it "should ignore a specified root element" do
    expect(OverrideGlobalIgnoredRootForFileExampleClient.root.title).to eq("Example Feed")
  end

  it "should ignore a specified root element" do
    expect(OverrideGlobalIgnoredRootForRequestExampleClient.root.title).to eq("Example Feed")
  end

  it "should wrap elements if specified, in form-encoded format" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q(base_data%5Bdebug%5D=true&base_data%5Btest%5D=foo), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    GlobalWrappedRootExampleClient.request_body_type :form_encoded
    GlobalWrappedRootExampleClient.wrapped id:1234, debug:true, test:'foo'
  end

  it "should wrap elements if specified, in form-encoded format" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q(class_specific_data%5Bdebug%5D=true&class_specific_data%5Btest%5D=foo), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    OverrideGlobalWrappedRootForFileExampleClient.request_body_type :form_encoded
    OverrideGlobalWrappedRootForFileExampleClient.wrapped id:1234, debug:true, test:'foo'
  end

  it "should wrap elements if specified, in form-encoded format" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q(request_specific_data%5Bdebug%5D=true&request_specific_data%5Btest%5D=foo), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    OverrideGlobalWrappedRootForRequestExampleClient.request_body_type :form_encoded
    OverrideGlobalWrappedRootForRequestExampleClient.wrapped id:1234, debug:true, test:'foo'
  end

  it "should encode the body wrapped in a root element in a JSON format if specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q({"base_data":{"debug":true,"test":"foo"}}), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    GlobalWrappedRootExampleClient.request_body_type :json
    GlobalWrappedRootExampleClient.wrapped id:1234, debug:true, test:'foo'
  end

  it "should encode the body wrapped in a root element in a JSON format if specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q({"class_specific_data":{"debug":true,"test":"foo"}}), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    OverrideGlobalWrappedRootForFileExampleClient.request_body_type :json
    OverrideGlobalWrappedRootForFileExampleClient.wrapped id:1234, debug:true, test:'foo'
  end

  it "should encode the body wrapped in a root element in a JSON format if specified" do
    expect_any_instance_of(Flexirest::Connection).to receive(:put).with("/put/1234", %q({"request_specific_data":{"debug":true,"test":"foo"}}), an_instance_of(Hash)).and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{\"result\":true}", response_headers:{})))
    OverrideGlobalWrappedRootForRequestExampleClient.request_body_type :json
    OverrideGlobalWrappedRootForRequestExampleClient.wrapped id:1234, debug:true, test:'foo'
  end

  context "Parameter preparation" do
    method = {url: "http://www.example.com", method: :get}
    object = nil

    it "should properly handle Hash params" do
      req = Flexirest::Request.new method, object, {hello: {}}
      req.prepare_params

      expect(req.get_params.is_a?(Hash)).to be_truthy
      expect(req.get_params[:hello]).to eq({})
    end

    it "should properly handle String params" do
      req = Flexirest::Request.new method, object, String.new
      req.prepare_params

      expect(req.get_params.is_a?(Hash)).to be_truthy
      expect(req.get_params[:id].is_a?(String)).to be_truthy
    end

    it "should properly handle Integer (Fixnum) params" do
      req = Flexirest::Request.new method, object, 1234
      req.prepare_params

      expect(req.get_params.is_a?(Hash)).to be_truthy
      expect(req.get_params[:id].is_a?(Integer)).to be_truthy
    end

    it "should properly handle Integer (Bignum) params" do
      req = Flexirest::Request.new method, object, 12345678901234567890
      req.prepare_params

      expect(req.get_params.is_a?(Hash)).to be_truthy
      expect(req.get_params[:id].is_a?(Integer)).to be_truthy
    end
  end
end
