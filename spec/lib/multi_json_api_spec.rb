require 'spec_helper'

describe "multi_json API" do
  before :each do
    class MultiJsonChildExample < Flexirest::Base
      base_url "http://www.example.com"

      get :find, "/child/:id"
    end

    class MultiJsonExampleClient < Flexirest::Base
      base_url "http://www.example.com"

      get :find, "/find/:id"
      get :parent, "/parent", lazy: { children: MultiJsonChildExample }, fake: "{\"children\": [\"http://www.example.com/child/1\"]}"
    end
  end

  # multi_json warns once per process for each deprecated entry point, so a
  # warning emitted by an earlier spec would make a later one look clean.
  # Message expectations on the deprecated surface - the legacy MultiJson module
  # (whose const_missing serves MultiJson::ParseError) and the load/dump aliases
  # on MultiJSON itself - hold regardless of spec order.
  def expect_no_deprecated_json_api
    [MultiJson, MultiJSON].each do |target|
      %i[load dump decode encode const_missing].each do |name|
        expect(target).to_not receive(name) if target.respond_to?(name)
      end
    end
  end

  def response_for(body)
    ::FaradayResponseMock.new(OpenStruct.new(status: 200, response_headers: { "Content-Type" => "application/json" }, body: body))
  end

  it "parses a response body" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(response_for("{\"name\":\"Billy\"}"))
    expect_no_deprecated_json_api

    expect(MultiJsonExampleClient.find(id: 1).name).to eq("Billy")
  end

  it "reports a body it cannot parse" do
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(response_for("{\"name\": Billy"))
    expect_no_deprecated_json_api

    expect { MultiJsonExampleClient.find(id: 1) }.to raise_error(Flexirest::ResponseParseException)
  end

  it "loads a lazy association" do
    loader = MultiJsonExampleClient.parent.children.first
    expect(loader).to be_an_instance_of(Flexirest::LazyAssociationLoader)
    expect_any_instance_of(Flexirest::Connection).to receive(:get).with(any_args).and_return(response_for("{\"name\":\"Jane\"}"))
    expect_no_deprecated_json_api

    expect(loader.name).to eq("Jane")
  end
end
