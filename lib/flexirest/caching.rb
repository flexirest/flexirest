module Flexirest
  module Caching
    module ClassMethods
      @@perform_caching = true

      def perform_caching(value = nil)
        @perform_caching = nil unless instance_variable_defined?(:@perform_caching)
        if value.nil?
          value = if @perform_caching.nil?
            @@perform_caching
          else
            @perform_caching
          end
          if value.nil? && superclass.respond_to?(:perform_caching)
            value = superclass.perform_caching
          end
          value
        else
          @perform_caching = value
        end
      end

      def perform_caching=(value)
        @@perform_caching = value
        @perform_caching = value
      end

      def cache_store=(value)
        @@cache_store = nil if value.nil? and return
        raise InvalidCacheStoreException.new("Cache store does not implement #read") unless value.respond_to?(:read)
        raise InvalidCacheStoreException.new("Cache store does not implement #write") unless value.respond_to?(:write)
        raise InvalidCacheStoreException.new("Cache store does not implement #fetch") unless value.respond_to?(:fetch)
        @@cache_store = value
      end

      def cache_store
        rails_cache_store = if Object.const_defined?(:Rails)
          ::Rails.try(:cache)
        else
          nil
        end
        (@@cache_store rescue nil) || rails_cache_store
      end

      def _reset_caching!
        @@perform_caching = nil
        @perform_caching = nil
        @@cache_store = nil
      end

      def read_cached_response(request, quiet)
        if cache_store && perform_caching && request.method[:method] == :get
          key = "#{request.class_name}:#{request.original_url}"
          Flexirest::Logger.debug "  \033[1;4;32m#{Flexirest.name}\033[0m #{key} - Trying to read from cache" unless quiet
          value = cache_store.read(key)
          value = Marshal.load(value) rescue value
        end
      end

      def write_cached_response(request, response, result, quiet)
        return if result.is_a? Symbol
        return unless perform_caching
        return unless !result.respond_to?(:_status) || [200, 304].include?(result._status)
        headers = response.response_headers

        headers.keys.select{|h| h.is_a? String}.each do |key|
          headers[key.downcase.to_sym] = headers[key]
        end

        if cache_store && (headers[:etag] || headers[:expires])
          key = "#{request.class_name}:#{request.original_url}"
          Flexirest::Logger.debug "  \033[1;4;32m#{Flexirest.name}\033[0m #{key} - Writing to cache" unless quiet
          cached_response = CachedResponse.new(status:response.status, result:result, response_headers: headers)
          cached_response.etag = "#{headers[:etag]}" if headers[:etag]
          cached_response.expires = Time.parse(headers[:expires]) rescue nil if headers[:expires]
          if cached_response.etag.present? || cached_response.expires
            cache_store.write(key, Marshal.dump(cached_response), {})
          end
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

  end

  class CachedResponse
    attr_accessor :class_name, :status, :etag, :expires, :response_headers

    def initialize(options)
      @status = options[:status]
      @etag = options[:etag]
      @expires = options[:expires]
      @response_headers = options[:response_headers]

      @class_name = options[:result].class.name
      if options[:result].is_a?(ResultIterator)
        @class_name = options[:result][0].class.name
        @result = options[:result].map{|i| {}.merge(i._attributes)}
      else
        @result = {}.merge(options[:result].try(:_attributes) || {})
      end
    end

    def result
      return @result if @class_name.nil? # Old cached instance

      if @result.is_a?(Array)
        ri = ResultIterator.new(self)
        ri.items = @result.map{|i| @class_name.constantize.new(i)}
        ri._clean!
        ri
      else
        obj = @class_name.constantize.new(@result)
        obj._clean!
        obj
      end
    end
  end
end
