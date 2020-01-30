require 'spec_helper'

describe Flexirest::Connection do
  before do
    @connection = Flexirest::Connection.new("http://www.example.com")
  end

  after do
    Flexirest::Base._reset_configuration!
    @connection.reconnect
  end

  it "should contain a Farday connection" do
    expect(@connection.session).to be_a_kind_of(Faraday::Connection)
  end

  it "should set the Base URL to be the one passed in" do
    expect(@connection.session.url_prefix.to_s).to eq("http://www.example.com/")
  end

  it "should set a user agent for the session" do
    expect(@connection.headers["User-Agent"]).to match(/^Flexirest\/[0-9.]+$/)
  end

  it "should try to Keep-Alive session connections" do
    expect(@connection.headers["Connection"]).to match(/Keep-Alive/)
  end

  it "should pass a GET request through to Faraday" do
    stub_request(:get, "www.example.com/foo").to_return(body: "{result:true}")
    result = @connection.get("/foo")
    expect(result.body).to eq("{result:true}")
  end

  it "should pass a PUT request through to Faraday" do
    stub_request(:put, "www.example.com/foo").with(body: "body").to_return(body: "{result:true}")
    result = @connection.put("/foo", "body")
    expect(result.body).to eq("{result:true}")
  end

  it "should pass a POST request through to Faraday" do
    stub_request(:post, "www.example.com/foo").with(body: "body").to_return(body: "{result:true}")
    result = @connection.post("/foo", "body")
    expect(result.body).to eq("{result:true}")
  end

  it "should pass a DELETE request through to Faraday" do
    stub_request(:delete, "www.example.com/foo").with(body: "body").to_return(body: "{result:true}")
    result = @connection.delete("/foo", "body")
    expect(result.body).to eq("{result:true}")
  end

  describe "with default Faraday headers" do
    before do
      @default_headers = { "User-Agent" => "Custom" }

      Flexirest::Base.faraday_config do |faraday|
        faraday.adapter Flexirest::Base.adapter
        faraday.headers.update(@default_headers)
      end
      @connection.reconnect
    end

    it "should pass a GET request through to Faraday preserving headers" do
      stub_request(:get, "www.example.com/foo").
        with(:headers => @default_headers).
        to_return(body: "{result:true}")

      result = @connection.get("/foo")
      expect(result.body).to eq("{result:true}")
    end

    it "should pass a PUT request through to Faraday" do
      stub_request(:put, "www.example.com/foo").
        with(body: "body").
        to_return(body: "{result:true}", :headers => @default_headers)

      result = @connection.put("/foo", "body")
      expect(result.body).to eq("{result:true}")
    end

    it "should pass a PUT request through to Faraday" do
      stub_request(:patch, "www.example.com/foo").
        with(body: "body").
        to_return(body: "{result:true}", :headers => @default_headers)

      result = @connection.patch("/foo", "body")
      expect(result.body).to eq("{result:true}")
    end

    it "should pass a POST request through to Faraday" do
      stub_request(:post, "www.example.com/foo").
        with(body: "body", :headers => @default_headers).
        to_return(body: "{result:true}")

      result = @connection.post("/foo", "body")
      expect(result.body).to eq("{result:true}")
    end

    it "should pass a DELETE request through to Faraday" do
      stub_request(:delete, "www.example.com/foo").
        with(:headers => @default_headers).
        to_return(body: "{result:true}")

      result = @connection.delete("/foo", "body")
      expect(result.body).to eq("{result:true}")
    end
  end

  context 'with custom timeouts' do
    it 'should set a custom timeout' do
      stub_request(:get, "www.example.com/foo")
        .to_return(body: "{result:true}")
      expect_any_instance_of(Flexirest::Connection).to receive(:set_per_request_timeout).and_call_original
      @connection.get("/foo", {:timeout => "5"})
    end
  end

  context 'with api auth signing requests' do
    before(:each) do
      # Need to still call this to load the api_auth library so tests work
      Flexirest::Base.api_auth_credentials('id123', 'secret123')

      @options = {
        :api_auth => {
          :api_auth_access_id => 'id123',
          :api_auth_secret_key => 'secret123',
          :api_auth_options => {}
        }
      }

      @default_headers = {'Date' => 'Sat, 14 Mar 2015 15:13:24 GMT'}

      Flexirest::Base.faraday_config do |faraday|
        faraday.adapter Flexirest::Base.adapter
        faraday.headers.update(@default_headers)
      end
      @connection.reconnect
    end

    it 'should have an Authorization header' do
      stub_request(:get, "www.example.com/foo")
        .with(:headers => @default_headers)
        .to_return(body: "{result:true}")
      result = @connection.get("/foo", @options)
      auth_header = result.env.request_headers['Authorization']
      expect(auth_header == "APIAuth id123:TQiQIW6vVaDC5jvh99uTNkxIg6Q=" || auth_header == "APIAuth id123:PMWBThkB8vKbvUccHvoqu9G3eVk=").to be_truthy
    end

    if  Gem.loaded_specs["api-auth"].present? && Gem.loaded_specs["api-auth"].version.to_s >= "2.0.0"
      it 'should have an Authorization header with a custom digest method' do
        @options[:api_auth][:api_auth_options] = {
          digest: "sha256"
        }
        stub_request(:get, "www.example.com/foo")
          .with(:headers => @default_headers)
          .to_return(body: "{result:true}")
        result = @connection.get("/foo", @options)
        expect(result.env.request_headers['Authorization']).to eq("APIAuth-HMAC-SHA256 id123:fDrJfQ1fOoPFHtzhqqdHby+v6bbn2K8b2HR5AKo3vmg=")
      end
    end

    it "should warn about using custom digest methods with an Authorization header if ApiAuth doesn't support it" do
      @options[:api_auth][:api_auth_options] = {
        digest: "sha256"
      }
      stub_request(:get, "www.example.com/foo")
        .with(:headers => @default_headers)
        .to_return(body: "{result:true}")
      expect(ApiAuth).to receive(:sign!).once.with(anything, anything, anything, {digest: "sha256"}).and_raise(ArgumentError)
      expect(ApiAuth).to receive(:sign!).once.with(anything, anything, anything).and_call_original
      expect(Flexirest::Logger).to receive(:warn)
      result = @connection.get("/foo", @options)
      auth_header = result.env.request_headers['Authorization']
      expect(auth_header == "APIAuth id123:TQiQIW6vVaDC5jvh99uTNkxIg6Q=" || auth_header == "APIAuth id123:PMWBThkB8vKbvUccHvoqu9G3eVk=").to be_truthy
    end

    it 'should have an Content-MD5 header' do
      stub_request(:put, "www.example.com/foo").
        with(body: "body", :headers => @default_headers).
        to_return(body: "{result:true}")

      result = @connection.put("/foo", "body", @options)
      expect(result.env.request_headers['Content-MD5']).to eq("hBotaJrYa9FhFEdFPCLG/A==")
    end
  end

  it "should retry once in the event of a connection failed" do
    stub_request(:get, "www.example.com/foo").to_raise(Faraday::ConnectionFailed.new("Foo"))
    expect { @connection.get("/foo") }.to raise_error(Flexirest::BaseException)
  end

  it "should raise an exception on timeout" do
    stub_request(:get, "www.example.com/foo").to_timeout
    expect { @connection.get("/foo") }.to raise_error(Flexirest::BaseException)
  end

  it "should raise an exception on timeout" do
    stub_request(:get, "www.example.com/foo").to_timeout
    begin
      @connection.get("foo")
      fail
    rescue Flexirest::TimeoutException => timeout
      expect(timeout.message).to eq("Timed out getting http://www.example.com/foo")
    end
  end
end
