module Flexirest
  module Callbacks
    module ClassMethods
      def before_request(method_name = nil, &block)
        @before_callbacks ||= []
        if block
          @before_callbacks << block
        elsif method_name
          @before_callbacks << method_name
        end
      end

      def after_request(method_name = nil, &block)
        @after_callbacks ||= []
        if block
          @after_callbacks << block
        elsif method_name
          @after_callbacks << method_name
        end
      end

      def _callback_request(type, name, param)
        _handle_super_class_callbacks(type, name, param)
        @before_callbacks ||= []
        @after_callbacks ||= []
        callbacks = (type == :before ? @before_callbacks : @after_callbacks)
        callbacks.each do |callback|
          if callback.is_a? Symbol
            if self.respond_to?(callback)
              result = self.send(callback, name, param)
            else
              instance = self.new
              result = instance.send(callback, name, param)
            end
          else
            result = callback.call(name, param)
          end
          if result == false
            return false
          end
          if result == :retry
            return :retry
          end
        end
      end

      def _handle_super_class_callbacks(type, name, request)
        @parents ||= []
        @parents.each do |parent|
          parent._callback_request(type, name, request)
        end
      end

      def _parents
        @parents ||= []
      end

      def inherited(subclass)
        subclass._parents << self
        super
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end
