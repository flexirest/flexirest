module Flexirest
  class BaseWithoutValidation
    include Mapping
    include Configuration
    include Callbacks
    include Caching
    include Recording
    include AttributeParsing
    include Associations

    attr_accessor :_status
    attr_accessor :_etag
    attr_accessor :_headers
    attr_accessor :_parent
    attr_accessor :_parent_attribute_name

    instance_methods.each do |m|
      next unless %w{display presence load require untrust trust freeze method enable_warnings with_warnings suppress capture silence quietly debugger breakpoint}.map(&:to_sym).include? m
      undef_method m
    end

    def initialize(attrs={})
      @attributes = {}
      @dirty_attributes = Hash.new

      raise Exception.new("Cannot instantiate Base class") if self.class == Flexirest::BaseWithoutValidation

      attrs.each do |attribute_name, attribute_value|
        attribute_name = attribute_name.to_sym
        @attributes[attribute_name] = parse_date?(attribute_name) ? parse_attribute_value(attribute_value) : attribute_value
        @dirty_attributes[attribute_name] = [nil, attribute_value]
      end
    end

    def _clean!
      @dirty_attributes = Hash.new
    end

    def _attributes
      @attributes
    end

    def _copy_from(result)
      @attributes = result._attributes
      @_status = result._status
      self._parent = result._parent
      self._parent_attribute_name = result._parent_attribute_name
      @attributes.each do |k,v|
        if v.respond_to?(:_parent) && v._parent.present?
          @attributes[k]._parent = self
        end
      end
      _clean!
    end

    def dirty?
      @dirty_attributes.size > 0
    end

    def changed?
      dirty?
    end

    # Returns an array of changed fields
    def changed
      @dirty_attributes.keys
    end

    # Returns hash of old and new values for each changed field
    def changes
      @dirty_attributes
    end

    def self._request(request, method = :get, params = nil, options = {})
      prepare_direct_request(request, method, options).call(params)
    end

    def self._plain_request(request, method = :get, params = nil, options = {})
      prepare_direct_request(request, method, options.merge(plain:true)).call(params)
    end

    def self._lazy_request(request, method = :get, params = nil, options = {})
      Flexirest::LazyLoader.new(prepare_direct_request(request, method, options), params)
    end

    def self.prepare_direct_request(request, method = :get, options={})
      unless request.is_a? Flexirest::Request
        options[:plain] ||= false
        options[:direct] ||= true
        request = Flexirest::Request.new({ url: request, method: method, options: options }, self)
      end
      request
    end

    def self._request_for(method_name, *args)
      if mapped = self._mapped_method(method_name)
        params = (args.first.is_a?(Hash) ? args.first : nil)
        request = Request.new(mapped, self, params)
        request
      else
        nil
      end
    end

    def [](key)
      @attributes[key.to_sym]
    end

    def []=(key, value)
      _set_attribute(key, value)
    end

    def each
      @attributes.each do |key, value|
        yield key, value
      end
    end

    def inspect
      inspection = if @attributes.any?
                     @attributes.collect { |key, value|
                       "#{key}: #{value_for_inspect(value)}"
                     }.compact.join(", ")
                   else
                     "[uninitialized]"
                   end
      inspection += "#{"," if @attributes.any?} ETag: #{@_etag}" unless @_etag.nil?
      inspection += "#{"," if @attributes.any?} Status: #{@_status}" unless @_status.nil?
      inspection += " (unsaved: #{@dirty_attributes.keys.map(&:to_s).join(", ")})" if @dirty_attributes.any?
      "#<#{self.class} #{inspection}>"
    end

    def method_missing(name, *args)
      if name.to_s[-1,1] == "="
        name = name.to_s.chop.to_sym
        _set_attribute(name, args.first)
      else
        name_sym = name.to_sym
        name = name.to_s

        if @attributes.has_key? name_sym
          @attributes[name_sym]
        else
          if name[/^lazy_/] && mapped = self.class._mapped_method(name_sym)
            if mapped[:method] != :delete
              raise ValidationFailedException.new if respond_to?(:valid?) && !valid?
            end

            request = Request.new(mapped, self, args.first)
            Flexirest::LazyLoader.new(request)
          elsif mapped = self.class._mapped_method(name_sym)
            if mapped[:method] != :delete
              raise ValidationFailedException.new if respond_to?(:valid?) && !valid?
            end

            request = Request.new(mapped, self, args.first)
            request.call
          elsif name[/_was$/] and @attributes.has_key? (name.sub(/_was$/,'').to_sym)
            k = (name.sub(/_was$/,'').to_sym)
            @dirty_attributes[k][0]
          elsif name[/^reset_.*!$/] and @attributes.has_key? (name.sub(/^reset_/,'').sub(/!$/,'').to_sym)
            k = (name.sub(/^reset_/,'').sub(/!$/,'').to_sym)
            _reset_attribute(k)
          elsif self.class.whiny_missing
            raise NoAttributeException.new("Missing attribute #{name_sym}")
          else
            nil
          end
        end
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @attributes.has_key? method_name.to_sym
    end

    def to_hash
      output = {}
      @attributes.each do |key, value|
        if value.is_a? Flexirest::Base
          output[key.to_s] = value.to_hash
        elsif value.is_a? Array
          output[key.to_s] = value.map(&:to_hash)
        else
          output[key.to_s] = value
        end
      end
      output
    end

    def to_json
      output = to_hash
      output.to_json
    end

    def _set_dirty(key)
      @dirty_attributes[key.to_sym] = true
    end

    private

    def _set_attribute(key, value)
      old_value = @dirty_attributes[key.to_sym]
      old_value = @attributes[key.to_sym] unless old_value
      old_value = old_value[0] if old_value and old_value.is_a? Array
      @dirty_attributes[key.to_sym] = [old_value, value] if old_value != value
      if _parent
        _parent._set_dirty(_parent_attribute_name)
      end
      @attributes[key.to_sym] = value
    end

    def _reset_attribute(key)
      old_value = @dirty_attributes[key.to_sym]
      @attributes[key.to_sym] = old_value[0] if old_value and old_value.is_a? Array
      @dirty_attributes.delete(key.to_sym)
    end

    def value_for_inspect(value)
      if value.is_a?(String) && value.length > 50
        "#{value[0..50]}...".inspect
      elsif value.is_a?(Date) || value.is_a?(Time)
        %("#{value.respond_to?(:to_fs) ? value.to_fs(:db) : value.to_s(:db)}")
      else
        value.inspect
      end
    end

    def parse_date?(name)
      return true if self.class._date_fields.include?(name)
      return true if !Flexirest::Base.disable_automatic_date_parsing && self.class._date_fields.empty?
      false
    end

  end
end
