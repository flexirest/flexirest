require 'spec_helper'

describe Flexirest::ResultIterator do
  let(:response) { double(status: 200, response_headers: { some: 'header'}) }

  it "should be able to have a status set during creation" do
    result = Flexirest::ResultIterator.new(response)
    expect(result._status).to eq(200)
  end

  it "should be able to have headers set during creation" do
    result = Flexirest::ResultIterator.new(response)
    expect(result._headers).to eq({ some: 'header'})
  end

  it "should be able to have a status set after creation" do
    result = Flexirest::ResultIterator.new
    result._status = 200
    expect(result._status).to eq(200)
  end

  it "should remember objects given to it" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result.each do |element|
      expect(element).to eq("a")
    end
  end

  it "should implement first" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "z"
    expect(result.first).to eq("a")
  end

  it "should implement join" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "z"
    expect(result.join(",")).to eq("a,z")
  end

  it "should implement any?" do
    result = Flexirest::ResultIterator.new
    expect(result.any?).to be_falsey
    result << "a"
    expect(result.any?).to be_truthy
  end

  it "should implement items" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "ab"
    expect(result.items).to eq(["a","ab"])
  end

  it "should implement last" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "z"
    expect(result.last).to eq("z")
  end

  it "should implement size" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "z"
    expect(result.size).to eq(2)
  end

  it "should implement index" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "z"
    expect(result.index("z")).to eq(1)
    expect(result.index { |i| i == "z" }).to eq(1)
  end

  it "should implement empty?" do
    result = Flexirest::ResultIterator.new
    expect(result.empty?).to be_truthy
    result << "a"
    result << "z"
    expect(result.empty?).to be_falsey
  end

  it "should implement reverse" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "z"
    expect(result.reverse.first).to eq("z")
    expect(result.reverse.last).to eq("a")
  end

  it "should implement direct index access" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "z"
    expect(result[0]).to eq("a")
    expect(result[1]).to eq("z")
  end

  it "should implement shuffle" do
    result = Flexirest::ResultIterator.new
    100.times do |n|
      result << n
    end
    expect(result.shuffle.first == result.shuffle.first && result.shuffle.first == result.shuffle.first).to_not be_truthy
  end

  it "should implement delete_if" do
    result = Flexirest::ResultIterator.new
    result << "a"
    result << "z"
    result.delete_if {|i| i == "z" }
    expect(result.items).to eq(["a"])
  end

  it "can filter results by simple matching criteria" do
    class Something < Flexirest::Base
    end

    results = Flexirest::ResultIterator.new
    results << Something.new(type: "foo")
    results << Something.new(type: "foo")
    results << Something.new(type: "bar")

    expect(results.where(type: "foo").count).to eq(2)
  end

  it "can filter results using regular expression matching criteria" do
    class Something < Flexirest::Base
    end

    results = Flexirest::ResultIterator.new
    results << Something.new(type: "fooo")
    results << Something.new(type: "foo")
    results << Something.new(type: "fo")
    results << Something.new(type: "bar")

    expect(results.where(type: /foo+/).count).to eq(2)
  end

  it "can parallelise calls to each item" do
    result = Flexirest::ResultIterator.new
    result << 3
    result << 2
    result << 1
    delay = 0.05
    start_time = Time.now
    response = result.parallelise do |item|
      sleep(delay * item)
      item*2
    end
    end_time = Time.now
    expect(end_time-start_time).to be < (6*delay)
    expect(response).to eq([6,4,2])
  end

  it "raises an error if you call paginate without WillPaginate installed" do
    result = Flexirest::ResultIterator.new
    result << 3
    expect{result.paginate}.to raise_error(Flexirest::WillPaginateNotAvailableException)
  end

  it "returns a WillPaginate::Collection if you call paginate with WillPaginate installed" do
    result = Flexirest::ResultIterator.new
    result << 3

    module ::WillPaginate
      class Collection ; end
    end
    allow(::WillPaginate).to receive(:per_page).and_return(10)
    collection = double("WillPaginate::Collection")
    allow(collection).to receive(:create).with(page: 1, per_page: 2).and_return(collection)
    allow(::WillPaginate::Collection).to receive(:create).and_return(collection)
    expect(result.paginate(page: 1, per_page: 2)).to eq(collection)
    Object.send(:remove_const, :WillPaginate)
  end
end
