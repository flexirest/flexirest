module Flexirest
  class Logger
    @logfile = nil
    @messages = []
    # Guards the shared in-memory buffer / logfile handle below, which are
    # written on every log call during request handling. Without this,
    # concurrent requests racing on `@messages << ...` (or a shared IO) can
    # interleave and lose or corrupt entries.
    @mutex = Mutex.new

    def self.logfile=(value)
      @mutex.synchronize { @logfile = value }
    end

    def self.messages
      @mutex.synchronize { @messages.dup }
    end

    def self.reset!
      @mutex.synchronize do
        @logfile = nil
        @messages = []
      end
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
      else
        write_fallback(message)
      end
    end

    def self.info(message)
      if defined?(Rails) && Rails.logger.present?
        Rails.logger.info(message)
      else
        write_fallback(message)
      end
    end

    def self.warn(message)
      if defined?(Rails) && Rails.logger.present?
        Rails.logger.warn(message)
      else
        write_fallback(message)
      end
    end

    def self.error(message)
      if defined?(Rails) && Rails.logger.present?
        Rails.logger.error(message)
      else
        write_fallback(message)
      end
    end

    # Writes to the configured logfile, or falls back to the in-memory buffer.
    # Synchronised because both destinations are shared across threads.
    def self.write_fallback(message)
      @mutex.synchronize do
        if @logfile
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
    private_class_method :write_fallback
  end
end
