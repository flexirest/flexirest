module Flexirest
  module Associations
    module ClassMethods
      include ActiveSupport::Inflector

      def has_many(key, klass = nil)
        if klass.nil?
          klass = key.to_s.classify.constantize
        end

        @_associations ||= {}
        @_associations[key] = klass
        define_method(key) do
          unless _attributes[key].is_a?(Array) || _attributes[key].is_a?(Flexirest::ResultIterator)
            return _attributes[key]
          end

          if _attributes[key].size == 0
            return _attributes[key]
          end

          if _attributes[key][0].is_a?(klass)
            return _attributes[key]
          end

          _attributes[key].each_with_index do |v, k|
            _attributes[key][k] = klass.new(v)
          end

          _attributes[key]
        end
      end

      def has_one(key, klass = nil)
        if klass.nil?
          klass = key.to_s.classify.constantize
        end

        @_associations ||= {}
        @_associations[key] = klass
        define_method(key) do
          return nil if _attributes[key].nil?

          if _attributes[key].is_a?(klass)
            return _attributes[key]
          end

          _attributes[key] = klass.new(_attributes[key])

          _attributes[key]
        end
      end

      def parse_date(*keys)
        keys.each { |key| @_date_fields << key }
      end

      def _date_fields
        @_date_fields.uniq
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@_date_fields, [])
        super
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
