require 'spec_helper'

class CallbacksExample
  include Flexirest::Callbacks

  before_request do |name, request|
    request.get_params[:callback1] = "Hello"
  end

  before_request do |name, request|
    request.post_params[:post_callback1] = "World"
  end

  before_request do |name, request|
    request.headers["X-My-Header"] = "myvalue"
  end

  before_request :set_to_ssl
  before_request :set_via_instance

  after_request :change_body

  private

  def self.set_to_ssl(name, request)
    request.url.gsub!("http://", "https://")
  end

  def set_via_instance(name, request)
    request.url.gsub!("//www", "//new")
  end

  def change_body(name, response)
    response.body = "{test: 1}"
  end
end

class SubClassedCallbacksExample < CallbacksExample
  before_request do |name, request|
    request.get_params[:api_key] = 1234
  end
end

describe Flexirest::Callbacks do
  let(:request) { OpenStruct.new(get_params:{}, post_params:{}, url:"http://www.example.com", headers:Flexirest::HeadersList.new) }
  let(:response) { OpenStruct.new(body:"") }

  it "should call through to adjust the parameters" do
    CallbacksExample._callback_request(:before, :test, request)
    expect(request.get_params).to have_key(:callback1)
  end

  it "should call through for more than one callback" do
    CallbacksExample._callback_request(:before, :test, request)
    expect(request.get_params).to have_key(:callback1)
    expect(request.post_params).to have_key(:post_callback1)
  end

  it "should allow adjusting the URL via a named callback" do
    CallbacksExample._callback_request(:before, :test, request)
    expect(request.url).to match(/https:\/\//)
  end

  it "should allow adjusting the URL via a named callback as an instance method" do
    CallbacksExample._callback_request(:before, :test, request)
    expect(request.url).to match(/\/\/new\./)
  end

  it "should allow callbacks to be set on the parent or on the child" do
    SubClassedCallbacksExample._callback_request(:before, :test, request)
    expect(request.url).to match(/\/\/new\./)
    expect(request.get_params[:api_key]).to eq(1234)
  end

  it "should allow callbacks to add custom headers" do
    CallbacksExample._callback_request(:before, :test, request)
    expect(request.headers["X-My-Header"]).to eq("myvalue")
  end

  it "should be able to alter the response body" do
    CallbacksExample._callback_request(:after, :test, response)
    expect(response.body).to eq("{test: 1}")
  end
end
