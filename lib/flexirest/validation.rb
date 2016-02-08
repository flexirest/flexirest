module Flexirest
  module Validation
    module ClassMethods
      def validates(field_name, options={}, &block)
        @_validations ||= []
        @_validations << {field_name:field_name, options:options, block:block}
      end

      def _validations
        @_validations ||= []
        @_validations
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def valid?
      @errors = Hash.new {|h,k| h[k] = []}
      self.class._validations.each do |validation|
        value = self.send(validation[:field_name])
        allow_nil = validation[:options].fetch(:allow_nil, false)
        validation[:options].each do |type, options|
          if type == :presence
            if value.nil?
              @errors[validation[:field_name]] << "must be present"
            elsif value.blank?
              @errors[validation[:field_name]] << "must be present"
            end
          elsif type == :existence
            if value.nil?
              @errors[validation[:field_name]] << "must be not be nil"
            end
          elsif type == :length
            if value.nil?
              @errors[validation[:field_name]] << "must be not be nil" unless allow_nil
            else
              if options[:within]
                @errors[validation[:field_name]] << "must be within range #{options[:within]}" unless options[:within].include?(value.to_s.length )
              end
              if options[:minimum]
                @errors[validation[:field_name]] << "must be at least #{options[:minimum]} characters long" unless value.to_s.length >= options[:minimum]
              end
              if options[:maximum]
                @errors[validation[:field_name]] << "must be no more than #{options[:maximum]} characters long" unless value.to_s.length <= options[:maximum]
              end
            end
          elsif type == :numericality
            if value.nil?
              @errors[validation[:field_name]] << "must be not be nil" unless allow_nil
            else
              numeric = (true if Float(value) rescue false)
              if !numeric
                @errors[validation[:field_name]] << "must be numeric"
              else
                if options.is_a?(Hash)
                  if options[:minimum]
                    @errors[validation[:field_name]] << "must be at least #{options[:minimum]}" unless value.to_f >= options[:minimum]
                  end
                  if options[:maximum]
                    @errors[validation[:field_name]] << "must be no more than #{options[:maximum]}" unless value.to_f <= options[:maximum]
                  end
                end
              end
            end
          elsif type == :minimum
            if value.nil?
              @errors[validation[:field_name]] << "must be not be nil" unless allow_nil
            else
              @errors[validation[:field_name]] << "must be at least #{options}" unless value.to_f >= options.to_f
            end
          elsif type == :maximum
            if value.nil?
              @errors[validation[:field_name]] << "must be not be nil" unless allow_nil
            else
              @errors[validation[:field_name]] << "must be no more than #{options}" unless value.to_f <= options.to_f
            end
          elsif type == :inclusion
            if value.nil?
              @errors[validation[:field_name]] << "must be not be nil" unless allow_nil
            else
              @errors[validation[:field_name]] << "must be included in #{options[:in].join(", ")}" unless options[:in].include?(value)
            end
          end
        end
        if validation[:block]
          validation[:block].call(self, validation[:field_name], value)
        end
      end
      @errors.empty?
    end

    def full_error_messages
      return "" unless _errors.present?
      _errors.reduce([]) do |memo, (field, errors)|
        memo << "#{field.to_s} #{errors.join(' and ')}"
      end
    end

    def _errors
      @errors ||= Hash.new {|h,k| h[k] = []}
      @errors
    end
  end

end
