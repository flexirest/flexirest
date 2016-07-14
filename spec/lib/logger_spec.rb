require 'spec_helper'

describe Flexirest::Instrumentation do
  before :each do
    Flexirest::Logger.reset!
  end

  it "should log things to the Rails logger if available" do
    class Rails
      class << self
        attr_accessor :logger
      end
    end

    Rails.logger = double("Logger")
    expect(Rails.logger).to receive(:debug)
    expect(Rails.logger).to receive(:info)
    expect(Rails.logger).to receive(:warn)
    expect(Rails.logger).to receive(:error)
    Flexirest::Logger.debug("Hello world")
    Flexirest::Logger.info("Hello world")
    Flexirest::Logger.warn("Hello world")
    Flexirest::Logger.error("Hello world")
    Object.send(:remove_const, :Rails)
  end

  it "should write to a logfile if one has been specified" do
    Flexirest::Logger.logfile = "/dev/null"
    file = double('file')
    expect(File).to receive(:open).with("/dev/null", "a").and_yield(file)
    expect(file).to receive(:<<).with("Hello world\n")
    Flexirest::Logger.debug("Hello world")

    file = double('file')
    expect(File).to receive(:open).with("/dev/null", "a").and_yield(file)
    expect(file).to receive(:<<).with("Hello info\n")
    Flexirest::Logger.info("Hello info")

    file = double('file')
    expect(File).to receive(:open).with("/dev/null", "a").and_yield(file)
    expect(file).to receive(:<<).with("Hello error\n")
    Flexirest::Logger.error("Hello error")

    file = double('file')
    expect(File).to receive(:open).with("/dev/null", "a").and_yield(file)
    expect(file).to receive(:<<).with("Hello warn\n")
    Flexirest::Logger.warn("Hello warn")
    Flexirest::Logger.logfile = nil
  end

  it "should write to STODOUT if one has been specified" do
    Flexirest::Logger.logfile = STDOUT
    expect(STDOUT).to receive(:<<).with("Hello world\n")
    Flexirest::Logger.debug("Hello world")

    expect(STDOUT).to receive(:<<).with("Hello info\n")
    Flexirest::Logger.info("Hello info")

    expect(STDOUT).to receive(:<<).with("Hello error\n")
    Flexirest::Logger.error("Hello error")

    expect(STDOUT).to receive(:<<).with("Hello warn\n")
    Flexirest::Logger.warn("Hello warn")
    Flexirest::Logger.logfile = nil
  end

  it "should append to its own messages list if neither Rails nor a logfile has been specified" do
    expect(File).not_to receive(:open)
    Flexirest::Logger.debug("Hello world")
    Flexirest::Logger.info("Hello info")
    Flexirest::Logger.warn("Hello warn")
    Flexirest::Logger.error("Hello error")
    expect(Flexirest::Logger.messages.size).to eq(4)
    expect(Flexirest::Logger.messages[0]).to eq("Hello world")
    expect(Flexirest::Logger.messages[1]).to eq("Hello info")
    expect(Flexirest::Logger.messages[2]).to eq("Hello warn")
    expect(Flexirest::Logger.messages[3]).to eq("Hello error")
  end

end
