module Flexirest
  class Logger
    @logfile = nil
    @messages = []

    def self.logfile=(value)
      @logfile = value
    end

    def self.messages
      @messages
    end

    def self.reset!
      @logfile = nil
      @messages = []
    end

    def self.level
      if defined?(Rails) && Rails.logger.present?
        Rails.logger.level
      else
        0
      end
    end

    def self.debug(message)
      if defined?(Rails) && Rails.logger.present?
        Rails.logger.debug(message)
      elsif @logfile
        if @logfile.is_a?(String)
          File.open(@logfile, "a") do |f|
            f << "#{message}\n"
          end
        else
          @logfile << "#{message}\n"
        end
      else
        @messages << message
      end
    end

    def self.info(message)
      if defined?(Rails) && Rails.logger.present?
        Rails.logger.info(message)
      elsif @logfile
        if @logfile.is_a?(String)
          File.open(@logfile, "a") do |f|
            f << "#{message}\n"
          end
        else
          @logfile << "#{message}\n"
        end
      else
        @messages << message
      end
    end

    def self.warn(message)
      if defined?(Rails) && Rails.logger.present?
        Rails.logger.warn(message)
      elsif @logfile
        if @logfile.is_a?(String)
          File.open(@logfile, "a") do |f|
            f << "#{message}\n"
          end
        else
          @logfile << "#{message}\n"
        end
      else
        @messages << message
      end
    end

    def self.error(message)
      if defined?(Rails) && Rails.logger.present?
        Rails.logger.error(message)
      elsif @logfile
        if @logfile.is_a?(String)
          File.open(@logfile, "a") do |f|
            f << "#{message}\n"
          end
        else
          @logfile << "#{message}\n"
        end
      else
        @messages << message
      end
    end
  end
end
