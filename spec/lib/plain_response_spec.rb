require 'spec_helper'

describe Flexirest::PlainResponse do
  let(:response) { OpenStruct.new(status:200, body:"fake response", response_headers:{"X-ARC-Faked-Response" => "true", "Content-Type" => "application/json"}) }

  it "is comparable to a string" do
    expect(Flexirest::PlainResponse.new("test")).to eq "test"
  end

  it "can be instantiated from a response" do
    expect(Flexirest::PlainResponse.from_response(response)).to eq "fake response"
  end

  it "returns the response's status" do
    expect(Flexirest::PlainResponse.from_response(response)._status).to eq 200
  end

  it "returns the response's headers" do
    expect(Flexirest::PlainResponse.from_response(response)._headers["Content-Type"]).to eq "application/json"
  end
end
