require 'spec_helper'

describe Flexirest::ConnectionManager do
  before(:each) do
    Flexirest::ConnectionManager.reset!
  end

  # IMPORTANT: The two typhoeus examples below set a *global* adapter. Reset it in an
  # after hook rather than on the last line of each example: if the example raises
  # first that line never runs, every later spec in the suite inherits
  # adapter = :typhoeus, and they all fail with ":typhoeus is not registered on
  # Faraday::Adapter". Specs run in random order, so that turns one local failure into
  # a suite-wide cascade whose size depends on the seed.
  after(:each) do
    Flexirest::Base._reset_configuration!
  end

  # Gem.loaded_specs only lists gems that have been *activated*, not every gem in the
  # bundle, so it is not a reliable way to ask whether faraday-typhoeus is installed -
  # when it reads as absent the require is skipped and :typhoeus is never registered.
  # Just attempt the require and let the older typhoeus-provided adapter be the
  # fallback.
  def require_typhoeus_adapter
    require 'faraday/typhoeus'
  rescue LoadError
    require 'typhoeus/adapters/faraday'
  end

  it "should have a get_connection method" do
    expect(Flexirest::ConnectionManager).to respond_to("get_connection")
  end

  it "should return a connection for a given base url" do
    connection = Flexirest::ConnectionManager.get_connection("http://www.example.com")
    expect(connection).to be_kind_of(Flexirest::Connection)
  end

  it "should return the same connection for each base url when re-requested" do
    connection = Flexirest::ConnectionManager.get_connection("http://www.example.com")
    expect(Flexirest::ConnectionManager.get_connection("http://www.example.com")).to eq(connection)
  end

  it "should return different connections for each base url when requested" do
    base_url = "http://www.example.com"
    other_base_url = "http://other.example.com"
    expect(Flexirest::ConnectionManager.get_connection(base_url).base_url).to eq(base_url)
    expect(Flexirest::ConnectionManager.get_connection(other_base_url).base_url).to eq(other_base_url)
    expect(Thread.current[:_connections].size).to eq(2)
  end

  it "should find a connection if you pass in URLs containing an existing connection's base_url" do
    base_url         = "http://www.example.com"
    connection       = Flexirest::ConnectionManager.get_connection(base_url)
    found_connection = Flexirest::ConnectionManager.find_connection_for_url("#{base_url}:8080/people/test")
    expect(found_connection).to eq(connection)
  end

  it "should call 'in_parallel' for a session and yield procedure inside that block" do
    require_typhoeus_adapter
    Flexirest::Base.adapter = :typhoeus
    Flexirest::ConnectionManager.get_connection("http://www.example.com").session
    expect { |b| Flexirest::ConnectionManager.in_parallel("http://www.example.com", &b)}.to yield_control
  end

  it "should raise Flexirest::MissingOptionalLibraryError if Typhoeus isn't available" do
    require_typhoeus_adapter
    Flexirest::Base.adapter = :typhoeus
    Flexirest::ConnectionManager.get_connection("http://www.example.com").session
    expect(Flexirest::ConnectionManager).to receive(:require).and_raise(LoadError)
    expect { Flexirest::ConnectionManager.in_parallel("http://www.example.com")}.to raise_error(Flexirest::MissingOptionalLibraryError)
  end
end
