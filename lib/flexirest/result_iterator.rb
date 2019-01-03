module Flexirest
  class ResultIterator
    include Enumerable

    attr_accessor :_status, :items
    attr_reader :_headers

    def initialize(response = nil)
      @_status  = response.try :status
      @_headers = response.try :response_headers
      @items = []
    end

    def <<(item)
      @items << item
    end

    def size
      @items.size
    end

    def to_a
      @items
    end

    def join(*args)
      @items.join(*args)
    end

    def index(value)
      @items.index(value)
    end

    def empty?
      size == 0
    end

    def reverse
      @reversed_items ||= @items.reverse
    end

    def each
      @items.each do |el|
        yield el
      end
    end

    def last
      @items.last
    end

    def [](key)
      @items[key]
    end

    def []=(key, value)
      @items[key] = value
    end

    def shuffle
      @items = @items.shuffle
      self
    end

    def delete_if
      @items = @items.delete_if &Proc.new
      self
    end

    def where(criteria={})
      @items.select do |object|
        select = true
        criteria.each do |k, v|
          if v.is_a?(Regexp)
            select = false if !object[k][v]
          else
            select = false if object[k] != v
          end
        end
        select
      end
    end

    def parallelise(method=nil)
      collected_responses = []
      threads = []
      @items.each do |item|
        threads << Thread.new do
          ret = item.send(method) if method
          ret = yield(item) if block_given?
          Thread.current[:response] = ret
        end
      end
      threads.each do |t|
        t.join
        collected_responses << t[:response]
      end
      collected_responses
    end

    def paginate(options = {})
      raise WillPaginateNotAvailableException.new unless Object.constants.include?(:WillPaginate)

      page     = options[:page] || 1
      per_page = options[:per_page] || WillPaginate.per_page
      total    = options[:total_entries] || @items.length

      WillPaginate::Collection.create(page, per_page, total) do |pager|
        pager.replace @items[pager.offset, pager.per_page].to_a
      end
    end

  end

  class WillPaginateNotAvailableException < StandardError ; end
end
