require 'cgi'

module Flexirest
  module Configuration
    module ClassMethods
      @@base_url = nil
      @@alias_type = nil
      @@username = nil
      @@password = nil
      @@request_body_type = :form_encoded
      @@disable_automatic_date_parsing = nil
      @lazy_load = false
      @api_auth_access_id = nil
      @api_auth_secret_key = nil
      @api_auth_options = {}
      @ignore_root = nil
      @wrap_root = nil

      def ignore_root(value=nil)
        if value.nil?
          value = if @ignore_root.nil? && superclass.respond_to?(:ignore_root)
            superclass.ignore_root
          else
            @ignore_root
          end
        else
          @ignore_root = value
        end
      end

      def wrap_root(value=nil)
        if value.nil?
          value = if @wrap_root.nil? && superclass.respond_to?(:wrap_root)
            superclass.wrap_root
          else
            @wrap_root
          end
        else
          @wrap_root = value
        end
      end

      def base_url(value = nil)
        @base_url ||= nil
        @@base_url ||= nil
        if value.nil?
          value = if @base_url.nil?
            @@base_url
          else
            @base_url
          end
          if value.nil? && superclass.respond_to?(:base_url)
            value = superclass.base_url
          end
          value
        else
          if value.is_a?(Array)
            value.each_with_index do |v, k|
              value[k] = v.gsub(/\/$/, '')
            end
          else
            value = value.gsub(/\/$/, '')
          end
          @base_url = value
        end
      end

      def base_url=(value)
        Flexirest::Logger.info "\033[1;4;32m#{name}\033[0m Base URL set to be #{value}"
        value = value.gsub(/\/+$/, '')
        @@base_url = value
      end

      def username(value = nil, &block)
        @username ||= nil
        @@username ||= nil
        if value.nil?
          if block_given?
            @username = block
          else
            value = if @username.nil?
              @@username
            else
              @username
            end
            if value.nil? && superclass.respond_to?(:username)
              value = superclass.username
            end
            value
          end
        else
          if value.respond_to?(:call)
            @username = value
          else
            @username = value
          end
        end
      end

      def username=(value)
        Flexirest::Logger.info "\033[1;4;32m#{name}\033[0m Username set to be #{value}"
        @@username = value
      end

      def password(value = nil, &block)
        if value.nil?
          if block_given?
            @password = block
          else
            value = if @password.nil?
              @@password
            else
              @password
            end
            if value.nil? && superclass.respond_to?(:password)
              value = superclass.password
            end
            value
          end
        else
          if value.respond_to?(:call)
            @password = value
          else
            @password = value
          end
        end
      end

      def password=(value)
        Flexirest::Logger.info "\033[1;4;32m#{name}\033[0m Password set..."
        @@password = value
      end

      DEFAULT_BASIC_URL_METHOD = :url

      def basic_auth_method(value = nil)
        if value.nil? # Used as a getter method
          if @basic_auth_method.nil? && superclass.respond_to?(:basic_auth_method)
            superclass.basic_auth_method
          else
            @basic_auth_method || DEFAULT_BASIC_URL_METHOD
          end
        else # Used as a setter method
          unless [:header, :url].include?(value)
            raise %(Invalid basic_auth_method #{value.inspect}. Valid methods are :url (default) and :header.)
          end
          @basic_auth_method = value
        end
      end

      def alias_type(value = nil)
        @alias_type ||= nil
        if value.nil?
          if @alias_type.nil?
            if value.nil? && superclass.respond_to?(:alias_type)
              superclass.alias_type
            else
              @@alias_type || nil
            end
          else
            @alias_type
          end
        else
          @alias_type = value
        end
      end

      def request_body_type(value = nil)
        @request_body_type ||= nil
        if value.nil?
          if @request_body_type.nil?
            if value.nil? && superclass.respond_to?(:request_body_type)
              superclass.request_body_type
            else
              @@request_body_type || :form_encoded
            end
          else
            @request_body_type
          end
        else
          @request_body_type = value
        end
      end

      def request_body_type=(value)
        Flexirest::Logger.info "\033[1;4;32m#{name}\033[0m Request Body Type set to be #{value}"
        @@request_body_type = value
      end

      def disable_automatic_date_parsing(value = nil)
        @disable_automatic_date_parsing ||= nil
        if value.nil?
          if @disable_automatic_date_parsing.nil?
            if value.nil? && superclass.respond_to?(:disable_automatic_date_parsing)
              superclass.disable_automatic_date_parsing
            else
              @@disable_automatic_date_parsing || false
            end
          else
            @disable_automatic_date_parsing
          end
        else
          @disable_automatic_date_parsing = value
        end
      end

      def disable_automatic_date_parsing=(value)
        Flexirest::Logger.info "\033[1;4;32m#{name}\033[0m Request Body Type set to be #{value}"
        @@disable_automatic_date_parsing = value
      end

      def adapter=(adapter)
        Flexirest::Logger.info "\033[1;4;32m#{name}\033[0m Adapter set to be #{adapter}"
        @adapter = adapter
      end

      def adapter
        @adapter ||= Faraday.default_adapter
      end

      def faraday_config(&block)
        if block
          @faraday_config = block
        else
          @faraday_config ||= default_faraday_config
        end
      end

      def lazy_load!
        @lazy_load = true
      end

      def lazy_load?
        @lazy_load ||= false
      end

      def whiny_missing(value = nil)
        @whiny_missing ||= false
        value ? @whiny_missing = value : @whiny_missing
      end

      def api_auth_credentials(access_id, secret_key, options = {})
        begin
          require 'api-auth'
        rescue LoadError
          raise MissingOptionalLibraryError.new("You must include the gem 'api-auth' in your Gemfile to set api-auth credentials.")
        end

        @api_auth_access_id = access_id
        @api_auth_secret_key = secret_key
        @api_auth_options = options
      end

      def using_api_auth?
        !self.api_auth_access_id.nil? && !self.api_auth_secret_key.nil?
      end

      def api_auth_access_id
        @api_auth_access_id ||= nil
        if !@api_auth_access_id.nil?
          return @api_auth_access_id
        elsif self.superclass.respond_to?(:api_auth_access_id)
          return self.superclass.api_auth_access_id
        end

        return nil
      end

      def api_auth_secret_key
        if !@api_auth_secret_key.nil?
          return @api_auth_secret_key
        elsif self.superclass.respond_to?(:api_auth_secret_key)
          return self.superclass.api_auth_secret_key
        end

        return nil
      end

      def api_auth_options
        if !@api_auth_options.nil?
          return @api_auth_options
        elsif self.superclass.respond_to?(:api_auth_options)
          return self.superclass.api_auth_options
        end

        return {}
      end

      def verbose!
        @verbose = true
      end

      def verbose(value = nil)
        @verbose ||= false
        value ? @verbose = value : @verbose
      end

      def quiet!(options = {})
        @quiet = true
        @verbose = false
      end

      def quiet(value = nil)
        @quiet ||= false
        if value == true || value == false
          @quiet = value
          @verbose = false if @quiet != false
        end
        @quiet
      end

      def translator(value = nil)
        Flexirest::Logger.warn("DEPRECATION: The translator functionality of Flexirest has been replaced with proxy functionality, see https://github.com/andyjeffries/flexirest#proxying-apis for more information") unless value.nil?
        @translator ||= nil
        value ? @translator = value : @translator
      end

      def proxy(value = nil)
        @proxy ||= nil
        value ? @proxy = value : @proxy || nil

        if !@proxy.nil?
          return @proxy
        elsif self.superclass.respond_to?(:proxy)
          return self.superclass.proxy
        end
        nil
      end

      def _reset_configuration!
        @base_url             = nil
        @@base_url            = nil
        @request_body_type    = nil
        @@request_body_type   = nil
        @whiny_missing        = nil
        @lazy_load            = false
        @faraday_config       = default_faraday_config
        @adapter              = Faraday.default_adapter
        @api_auth_access_id   = nil
        @api_auth_secret_key  = nil
        @basic_auth_method    = :url
      end

      private

      def default_faraday_config
        Proc.new do |faraday|
          faraday.adapter(adapter)

          if faraday.options.respond_to?(:timeout=)
            faraday.options.timeout         = 10
            faraday.options.open_timeout    = 10
          else
            faraday.options['timeout']      = 10
            faraday.options['open_timeout'] = 10
          end

          faraday.headers['User-Agent'] = "Flexirest/#{Flexirest::VERSION}"
          faraday.headers['Connection'] = "Keep-Alive"
          faraday.headers['Accept']     = "application/json"
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end

  class InvalidCacheStoreException < StandardError ; end
end
