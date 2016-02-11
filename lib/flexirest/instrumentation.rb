module Flexirest
  class Instrumentation < ActiveSupport::LogSubscriber
    def request_call(event)
      self.class.time_spent += event.duration
      self.class.calls_made += 1
      name = '%s (%.1fms)' % [Flexirest.name, event.duration]
      Flexirest::Logger.debug "  \033[1;4;32m#{name}\033[0m #{event.payload[:name]}"
    end

    def self.time_spent=(value)
      @@time_spent = value
    end

    def self.time_spent
      @@time_spent ||= 0
    end

    def self.calls_made=(value)
      @@calls_made = value
    end

    def self.calls_made
      @@calls_made ||= 0
    end

    def self.reset
      @@time_spent = 0
      @@calls_made = 0
    end

    def logger
      Flexirest::Logger
    end
  end

  module ControllerInstrumentation
    extend ActiveSupport::Concern

    protected

    def append_info_to_payload(payload)
      super
      payload[:flexirest_time_spent] = Flexirest::Instrumentation.time_spent
      payload[:flexirest_calls_made] = Flexirest::Instrumentation.calls_made
    end

    module ClassMethods
      def log_process_action(payload)
        messages, time_spent, calls_made = super, payload[:flexirest_time_spent], payload[:flexirest_calls_made]
        messages << ("#{Flexirest.name}: %.1fms for %d calls" % [time_spent.to_f, calls_made]) if calls_made
        Flexirest::Instrumentation.reset
        messages
      end
    end
  end
end

Flexirest::Instrumentation.attach_to :flexirest

ActiveSupport.on_load(:action_controller) do
  include Flexirest::ControllerInstrumentation
end
