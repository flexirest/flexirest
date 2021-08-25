require "cgi"
require "multi_json"
require 'crack'
require 'crack/xml'

module Flexirest

  class Request
    include AttributeParsing
    include JsonAPIProxy
    include ActiveSupport::Inflector
    attr_accessor :post_params, :get_params, :url, :path, :headers, :method, :object, :body, :forced_url, :original_url, :retrying

    def initialize(method, object, params = {})
      @method                     = method
      @method[:options]           ||= {}
      @method[:options][:lazy]    ||= []
      @method[:options][:array]   ||= []
      @method[:options][:has_one] ||= {}
      @overridden_name            = @method[:options][:overridden_name]
      @object                     = object
      @response_delegate          = Flexirest::RequestDelegator.new(nil)
      @params                     = params
      @headers                    = HeadersList.new
      (@method[:options][:headers] || {}).each do |k,v|
        @headers[k] = v
      end
      @forced_url                 = nil
    end

    def object_is_class?
      !@object.respond_to?(:dirty?)
    end

    def model_class
      object_is_class? ? @object : @object.class
    end

    def class_name
      if object_is_class?
        @object.name
      else
        @object.class.name
      end
    end

    def original_object_class
      if object_is_class?
        @object
      else
        @object.class
      end
    end

    def base_url
      if object_is_class?
        url = @object.base_url
      else
        url = @object.class.base_url
      end
      if url.is_a?(Array)
        url = url.sample
      end
      url
    end

    def using_api_auth?
      if object_is_class?
        @object.using_api_auth?
      else
        @object.class.using_api_auth?
      end
    end

    def api_auth_access_id
      ret = nil
      if object_is_class?
        ret = @object.api_auth_access_id
        ret = ret.call if ret.respond_to?(:call)
      else
        ret = @object.class.api_auth_access_id
        ret = ret.call(@object) if ret.respond_to?(:call)
      end
      ret
    end

    def api_auth_secret_key
      ret = nil
      if object_is_class?
        ret = @object.api_auth_secret_key
        ret = ret.call if ret.respond_to?(:call)
      else
        ret = @object.class.api_auth_secret_key
        ret = ret.call(@object) if ret.respond_to?(:call)
      end
      ret
    end

    def api_auth_options
      if object_is_class?
        @object.api_auth_options
      else
        @object.class.api_auth_options
      end
    end

    def username
      ret = nil
      if object_is_class?
        ret = @object.username
        ret = ret.call if ret.respond_to?(:call)
      else
        ret = @object.class.username
        ret = ret.call(@object) if ret.respond_to?(:call)
      end
      ret
    end

    def password
      ret = nil
      if object_is_class?
        ret = @object.password
        ret = ret.call if ret.respond_to?(:call)
      else
       ret = @object.class.password
       ret = ret.call(@object) if ret.respond_to?(:call)
      end
      ret
    end

    def inject_basic_auth_in_url(url)
      url.gsub!(%r{//(.)}, "//#{username}:#{password}@\\1") if !url[%r{//[^/]*:[^/]*@}]
    end

    def using_basic_auth?
      !!username
    end

    def basic_auth_digest
      Base64.strict_encode64("#{username}:#{password}")
    end

    def request_body_type
      if @method[:options][:request_body_type]
        @method[:options][:request_body_type]
      elsif @object.nil?
        nil
      elsif object_is_class?
        @object.request_body_type
      else
        @object.class.request_body_type
      end
    end

    def ignore_root
      if @method[:options][:ignore_root]
        @method[:options][:ignore_root]
      elsif @object.nil?
        nil
      elsif object_is_class?
        @object.ignore_root
      else
        @object.class.ignore_root
      end
    end

    def wrap_root
      if @method[:options][:wrap_root]
        @method[:options][:wrap_root]
      elsif @object.nil?
        nil
      elsif object_is_class?
        @object.wrap_root
      else
        @object.class.wrap_root
      end
    end

    def verbose?
      if object_is_class?
        @object.verbose
      else
        @object.class.verbose
      end
    end

    def translator
      if object_is_class?
        @object.translator
      else
        @object.class.translator
      end
    end

    def proxy
      if object_is_class?
        @object.proxy
      else
        @object.class.proxy
      end
    rescue
      nil
    end

    def http_method
      @method[:method]
    end

    def get?
      http_method == :get
    end

    def post?
      http_method == :post
    end

    def put?
      http_method == :put
    end

    def delete?
      http_method == :delete
    end

    def call(explicit_parameters=nil)
      @instrumentation_name = "#{class_name}##{@method[:name]}"
      result = nil
      cached = nil
      ActiveSupport::Notifications.instrument("request_call.flexirest", :name => @instrumentation_name) do
        @explicit_parameters = explicit_parameters
        @body = nil
        prepare_params
        prepare_url
        fake = @method[:options][:fake]
        if fake.present?
          if fake.respond_to?(:call)
            fake = fake.call(self)
          elsif @object.respond_to?(fake)
            fake = @object.send(fake)
          elsif @object.class.respond_to?(fake)
            fake = @object.class.send(fake)
          elsif @object.new.respond_to?(fake)
            fake = @object.new.send(fake)
          elsif @object.class.new.respond_to?(fake)
            fake = @object.class.new.send(fake)
          end
          Flexirest::Logger.debug "  \033[1;4;32m#{Flexirest.name}\033[0m #{@instrumentation_name} - Faked response found"
          content_type = @method[:options][:fake_content_type] || "application/json"
          return handle_response(OpenStruct.new(status:200, body:fake, response_headers:{"X-ARC-Faked-Response" => "true", "Content-Type" => content_type}))
        end
        if object_is_class?
          callback_result = @object.send(:_callback_request, :before, @method[:name], self)
        else
          callback_result = @object.class.send(:_callback_request, :before, @method[:name], self)
        end
        if callback_result == false
          return false
        end

        append_get_parameters
        prepare_request_body
        self.original_url = self.url
        cached = original_object_class.read_cached_response(self)
        if cached && !cached.is_a?(String)
          if cached.expires && cached.expires > Time.now
            Flexirest::Logger.debug "  \033[1;4;32m#{Flexirest.name}\033[0m #{@instrumentation_name} - Absolutely cached copy found"
            return handle_cached_response(cached)
          elsif cached.etag.to_s != "" #present? isn't working for some reason
            Flexirest::Logger.debug "  \033[1;4;32m#{Flexirest.name}\033[0m #{@instrumentation_name} - Etag cached copy found with etag #{cached.etag}"
            etag = cached.etag
          end
        end

        response = (
          if proxy && proxy.is_a?(Class)
            proxy.handle(self) do |request|
              request.do_request(etag)
            end
          else
            do_request(etag)
          end
        )

        # This block is called immediately when this request is not inside a parallel request block.
        # Otherwise this callback is called after the parallel request block ends.
        response.on_complete do |response_env|
          if verbose?
            Flexirest::Logger.debug "  Response"
            Flexirest::Logger.debug "  << Status : #{response_env.status}"
            response_env.response_headers.each do |k,v|
              Flexirest::Logger.debug "  << #{k} : #{v}"
            end
            Flexirest::Logger.debug "  << Body:\n#{response_env.body}"
          end

          if object_is_class? && @object.record_response?
            @object.record_response(self.url, response_env)
          end

          begin
            if object_is_class?
              callback_result = @object.send(:_callback_request, :after, @method[:name], response_env)
            else
              callback_result = @object.class.send(:_callback_request, :after, @method[:name], response_env)
            end
          rescue Flexirest::CallbackRetryRequestException
            if self.retrying != true
              self.retrying = true
              return call()
            end
          end

          result = handle_response(response_env, cached)
          @response_delegate.__setobj__(result)
          original_object_class.write_cached_response(self, response_env, result) unless @method[:options][:skip_caching]
        end

        # If this was not a parallel request just return the original result
        return result if response.finished?
        # Otherwise return the delegate which will get set later once the call back is completed
        return @response_delegate
      end
    end

    def prepare_params
      if http_method == :post || http_method == :put || http_method == :patch
        params = (@object._attributes rescue {}).merge(@params || {}) rescue {}
      else
        params = @params || @object._attributes rescue {}
      end
      if params.is_a?(String) || params.is_a?(Integer)
        params = {id:params}
      end

      # Format includes parameter for jsonapi
      if proxy == :json_api
        JsonAPIProxy::Request::Params.translate(params, @object._include_associations)
        @object._reset_include_associations!
      end

      if @method[:options][:defaults].respond_to?(:call)
        default_params = @method[:options][:defaults].call(params)
      else
        default_params = @method[:options][:defaults] || {}
      end

      if @explicit_parameters
        params = @explicit_parameters
      end
      if http_method == :get
        @get_params = default_params.merge(params || {})
        @post_params = nil
      elsif http_method == :delete && @method[:options][:send_delete_body]
        @post_params = default_params.merge(params || {})
        @get_params = {}
      elsif params.is_a? String
        @post_params = params
        @get_params = {}
      else
        @post_params = (default_params || {}).merge(params || {})
        @get_params = {}
      end

      # Evaluate :only_changed
      if @method[:options][:only_changed]
        if http_method == :post or http_method == :put or http_method == :patch
          # we only ever mess with @post_params in here, because @get_params will/should never match our method criteria
          if @method[:options][:only_changed].is_a? Hash
            # only include the listed attributes marked 'true' when they are changed; attributed marked false are always included
            newPostHash = {}
            @method[:options][:only_changed].each_pair do |changed_attr_k,changed_attr_v|
              if changed_attr_v == false or @object.changes.has_key? changed_attr_k.to_sym
                newPostHash[changed_attr_k.to_sym] = @object[changed_attr_k.to_sym]
              end
            end
            @post_params = newPostHash
          elsif @method[:options][:only_changed].is_a? Array
            # only send these listed attributes, and only if they are changed
            newPostHash = {}
            @method[:options][:only_changed].each do |changed_attr|
              if @object.changes.has_key? changed_attr.to_sym
                newPostHash[changed_attr.to_sym] = @object[changed_attr.to_sym]
              end
            end
            @post_params = newPostHash
          else
            # only send attributes if they are changed, drop the rest
            newPostHash = {}
            @object.changed.each do |k|
              newPostHash[k] = @object[k]
            end
            @post_params = newPostHash
          end
        end
      end

      if @method[:options][:requires]
        requires = @method[:options][:requires].dup
        merged_params = @get_params.merge(@post_params || {})
        missing = []
        requires.each do |key|
          if merged_params[key.to_sym].blank? && ![true, false].include?(merged_params[key.to_sym])
            missing << key
          end
        end
        if missing.any?
          raise Flexirest::MissingParametersException.new("The following parameters weren't specifed: #{missing.join(", ")}")
        end
      end
    end

    def prepare_url
      missing = []
      if @forced_url && @forced_url.present?
        @url = @forced_url
      else
        @url = @method[:url].dup
        matches = @url.scan(/(:[a-z_-]+)/)
        @get_params ||= {}
        @post_params ||= {}
        matches.each do |token|
          token = token.first[1,999]
          # pull URL path variables out of @get_params/@post_params
          target = @get_params.delete(token.to_sym) || @post_params.delete(token.to_sym) || @get_params.delete(token.to_s) || @post_params.delete(token.to_s) || ""
          unless object_is_class?
            # it's possible the URL path variable may not be part of the request, in that case, try to resolve it from the object attributes
            target = @object._attributes[token.to_sym] || "" if target == ""
          end
          if target.to_s.blank?
            missing << token
          end
          @url.gsub!(":#{token}", URI.encode_www_form_component(target.to_s))
        end
      end

      if missing.present?
        raise Flexirest::MissingParametersException.new("The following parameters weren't specifed: #{missing.join(", ")}")
      end
    end

    def append_get_parameters
      if @get_params.any?
        if @method[:options][:params_encoder] == :flat
          @url += "?" + URI.encode_www_form(@get_params)
        else
          @url += "?" + @get_params.to_query
        end
      end
    end

    def prepare_request_body(params = nil)
      if proxy == :json_api
        if http_method == :get || (http_method == :delete && !@method[:options][:send_delete_body])
          @body = ""
        else
          headers["Content-Type"] ||= "application/vnd.api+json"
          @body = JsonAPIProxy::Request::Params.create(
            params || @post_params || {},
            object_is_class? ? @object.new : @object
          ).to_json
        end

        headers["Accept"] ||= "application/vnd.api+json"
        JsonAPIProxy::Headers.save(headers)
      elsif http_method == :get || (http_method == :delete && !@method[:options][:send_delete_body])
        if request_body_type == :form_encoded
          headers["Content-Type"] ||= "application/x-www-form-urlencoded; charset=utf-8"
        elsif request_body_type == :form_multipart
          headers["Content-Type"] ||= "multipart/form-data; charset=utf-8"
        elsif request_body_type == :json
          headers["Content-Type"] ||= "application/json; charset=utf-8"
        end
        @body = ""
      elsif request_body_type == :form_encoded
        @body ||= if params.is_a?(String)
          params
        elsif @post_params.is_a?(String)
          @post_params
        else
          p = (params || @post_params || {})
          if wrap_root.present?
            p = {wrap_root => p}
          end
          p.to_query
        end
        headers["Content-Type"] ||= "application/x-www-form-urlencoded"
      elsif request_body_type == :form_multipart
        headers["Content-Type"] ||= "multipart/form-data; charset=utf-8"
        @body ||= if params.is_a?(String)
          params
        elsif @post_params.is_a?(String)
          @post_params
        else
          p = (params || @post_params || {})
          if wrap_root.present?
            p = {wrap_root => p}
          end
          data, mp_headers = Flexirest::Multipart::Post.prepare_query(p)
          mp_headers.each do |k,v|
            headers[k] = v
          end
          data
        end
      elsif request_body_type == :json
        @body ||= if params.is_a?(String)
          params
        elsif @post_params.is_a?(String)
          @post_params
        else
          if wrap_root.present?
            {wrap_root => (params || @post_params || {})}.to_json
          else
            (params || @post_params || {}).to_json
          end
        end
        headers["Content-Type"] ||= "application/json; charset=utf-8"
      elsif request_body_type == :plain && @post_params[:body].present?
        @body = @post_params[:body]
        headers["Content-Type"] ||= "text/plain"
        headers["Content-Type"] = @post_params[:content_type] if @post_params[:content_type].present?
      end
    end

    def do_request(etag)
      http_headers = {}
      http_headers["If-None-Match"] = etag if etag && !@method[:options][:skip_caching]
      http_headers["Accept"] = "application/hal+json, application/json;q=0.5"
      headers.each do |key,value|
        value = value.join(",") if value.is_a?(Array)
        http_headers[key] = value
      end
      if @method[:options][:url] || @forced_url
        @url = @method[:options][:url] || @method[:url]
        @url = @forced_url if @forced_url
        if connection = Flexirest::ConnectionManager.find_connection_for_url(@url)
          @url = @url.slice(connection.base_url.length, 255)
        else
          parts = @url.match(%r{^(https?://[a-z\d\.:-]+?)(/.*)}).to_a
          if (parts.empty?) # Not a full URL, so use hostname/protocol from existing base_url
            uri = URI.parse(base_url)
            @base_url = "#{uri.scheme}://#{uri.host}#{":#{uri.port}" if uri.port != 80 && uri.port != 443}"
            @url = "#{base_url}#{@url}".gsub(@base_url, "")
          else
            _, @base_url, @url = parts
          end
          if using_basic_auth? && model_class.basic_auth_method == :url
            inject_basic_auth_in_url(base_url)
          end
          connection = Flexirest::ConnectionManager.get_connection(base_url)
        end
      else
        parts = @url.match(%r{^(https?://[a-z\d\.:-]+?)(/.*)?$}).to_a
        if (parts.empty?) # Not a full URL, so use hostname/protocol from existing base_url
          uri = URI.parse(base_url)
          @base_url = "#{uri.scheme}://#{uri.host}#{":#{uri.port}" if uri.port != 80 && uri.port != 443}"
          @url = "#{base_url}#{@url}".gsub(@base_url, "")
          base_url = @base_url
        else
          base_url = parts[0]
        end
        if using_basic_auth? && model_class.basic_auth_method == :url
          inject_basic_auth_in_url(base_url)
        end
        connection = Flexirest::ConnectionManager.get_connection(base_url)
      end
      if @method[:options][:direct]
        Flexirest::Logger.info "  \033[1;4;32m#{Flexirest.name}\033[0m #{@instrumentation_name} - Requesting #{@url}"
      else
        Flexirest::Logger.info "  \033[1;4;32m#{Flexirest.name}\033[0m #{@instrumentation_name} - Requesting #{connection.base_url}#{@url}"
      end

      if verbose?
        Flexirest::Logger.debug "Flexirest Verbose Log:"
        Flexirest::Logger.debug "  Request"
        Flexirest::Logger.debug "  >> #{http_method.upcase} #{@url} HTTP/1.1"
        http_headers.each do |k,v|
          Flexirest::Logger.debug "  >> #{k} : #{v}"
        end
        Flexirest::Logger.debug "  >> Body:\n#{@body}"
      end

      request_options = {:headers => http_headers}
      if using_api_auth?
        request_options[:api_auth] = {
          :api_auth_access_id => api_auth_access_id,
          :api_auth_secret_key => api_auth_secret_key,
          :api_auth_options => api_auth_options
        }
      elsif using_basic_auth? && model_class.basic_auth_method == :header
        http_headers["Authorization"] = "Basic #{basic_auth_digest}"
      end
      if @method[:options][:timeout]
        request_options[:timeout] = @method[:options][:timeout]
      end

      case http_method
      when :get
        response = connection.get(@url, request_options)
      when :put
        response = connection.put(@url, @body, request_options)
      when :post
        response = connection.post(@url, @body, request_options)
      when :patch
        response = connection.patch(@url, @body, request_options)
      when :delete
        response = connection.delete(@url, @body, request_options)
      else
        raise InvalidRequestException.new("Invalid method #{http_method}")
      end

      response
    end

    def handle_cached_response(cached)
      if cached.result.is_a? Flexirest::ResultIterator
        cached.result
      else
        if object_is_class?
          cached.result
        else
          @object._copy_from(cached.result)
          @object
        end
      end
    end

    def handle_response(response, cached = nil)
      @response = response
      status = @response.status || 200
      if @response.body.blank?
        @response.response_headers['Content-Type'] = "application/json"
        @response.body = "{}"
      end

      if cached && response.status == 304
        Flexirest::Logger.debug "  \033[1;4;32m#{Flexirest.name}\033[0m #{@instrumentation_name}" +
          ' - Etag copy is the same as the server'
        return handle_cached_response(cached)
      end

      if (200..399).include?(status)
        if @method[:options][:plain]
          return @response = Flexirest::PlainResponse.from_response(@response)
        elsif is_json_response? || is_xml_response?
          if @response.respond_to?(:proxied) && @response.proxied
            Flexirest::Logger.debug "  \033[1;4;32m#{Flexirest.name}\033[0m #{@instrumentation_name} - Response was proxied, unable to determine size"
          else
            Flexirest::Logger.debug "  \033[1;4;32m#{Flexirest.name}\033[0m #{@instrumentation_name} - Response received #{@response.body.size} bytes"
          end
          result = generate_new_object(ignore_root: ignore_root, ignore_xml_root: @method[:options][:ignore_xml_root])
          # TODO: Cleanup when ignore_xml_root is removed
        else
          raise ResponseParseException.new(status:status, body:@response.body, headers: @response.headers)
        end
      else
        if is_json_response? || is_xml_response?
          error_response = generate_new_object(mutable: false, ignore_xml_root: @method[:options][:ignore_xml_root])
        else
          error_response = @response.body
        end
        if status == 400
          raise HTTPBadRequestClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 401
          raise HTTPUnauthorisedClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 403
          raise HTTPForbiddenClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 404
          raise HTTPNotFoundClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 405
          raise HTTPMethodNotAllowedClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 406
          raise HTTPNotAcceptableClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 408
          raise HTTPTimeoutClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 409
          raise HTTPConflictClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 429
          raise HTTPTooManyRequestsClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 500
          raise HTTPInternalServerException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 501
          raise HTTPNotImplementedServerException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 502
          raise HTTPBadGatewayServerException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 503
          raise HTTPServiceUnavailableServerException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 504
          raise HTTPGatewayTimeoutServerException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif (400..499).include? status
          raise HTTPClientException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif (500..599).include? status
          raise HTTPServerException.new(status:status, result:error_response, raw_response: @response.body, url:@url, method: http_method)
        elsif status == 0
          raise TimeoutException.new("Timed out getting #{response.url}")
        end
      end
      result
    end

    def new_object(attributes, name = nil, parent = nil, parent_attribute_name = nil)
      @method[:options][:has_many] ||= {}
      name = name.to_sym rescue nil
      if @method[:options][:has_many][name]
        overridden_name = name
        object = @method[:options][:has_many][name].new
      elsif @method[:options][:has_one][name]
        overridden_name = name
        object = @method[:options][:has_one][name].new
      else
        object = create_object_instance
      end

      object._parent = parent
      object._parent_attribute_name = parent_attribute_name

      if hal_response? && name.nil?
        attributes = handle_hal_links_embedded(object, attributes)
      end

      attributes.each do |k,v|
        if @method[:options][:rubify_names]
          k = rubify_name(k)
        else
          k = k.to_sym
        end
        overridden_name = select_name(k, overridden_name)
        set_corresponding_value(v, k, object, overridden_name)
      end
      object.clean! unless object_is_class?

      object
    end

    def set_corresponding_value(value, key = nil, object = nil, overridden_name = nil)
      optional_args = [key, object, overridden_name]
      value_from_object = optional_args.all? # trying to parse a JSON Hash value
      value_from_other_type = optional_args.none? # trying to parse anything else
      raise Flexirest::InvalidArgumentsException.new("Optional args need all to be filled or none") unless value_from_object || value_from_other_type
      k = key || :key
      v = value
      assignable_hash = value_from_object ? object._attributes : {}
      if value_from_object && @method[:options][:lazy].include?(k)
        assignable_hash[k] = Flexirest::LazyAssociationLoader.new(overridden_name, v, self, overridden_name:(overridden_name), parent: object, parent_attribute_name: k)
      elsif v.is_a? Hash
        assignable_hash[k] = new_object(v, overridden_name, object, k)
      elsif v.is_a? Array
        if @method[:options][:array].include?(k)
          assignable_hash[k] = Array.new
        else
          assignable_hash[k] = Flexirest::ResultIterator.new
        end
        v.each do |item|
          if item.is_a? Hash
            assignable_hash[k] << new_object(item, overridden_name)
          else
            assignable_hash[k] << set_corresponding_value(item)
          end
        end
      else
        parse_fields = [ @method[:options][:parse_fields], @object._date_fields ].compact.reduce([], :|)
        parse_fields = nil if parse_fields.empty?
        if (parse_fields && parse_fields.include?(k))
          assignable_hash[k] = parse_attribute_value(v)
        elsif parse_fields
          assignable_hash[k] = v
        elsif Flexirest::Base.disable_automatic_date_parsing
          assignable_hash[k] = v
        else
          assignable_hash[k] = parse_attribute_value(v)
        end
      end
      value_from_object ? object : assignable_hash[k]
    end

    def hal_response?
      _, content_type = @response.response_headers.detect{|k,v| k.downcase == "content-type"}
      faked_response = @response.response_headers.detect{|k,v| k.downcase == "x-arc-faked-response"}
      if content_type && content_type.respond_to?(:each)
        content_type.each do |ct|
          return true if ct[%r{application\/hal\+json}i]
          return true if ct[%r{application\/json}i]
        end
        faked_response
      elsif content_type && (content_type[%r{application\/hal\+json}i] || content_type[%r{application\/json}i]) || faked_response
        true
      else
        false
      end
    end

    def handle_hal_links_embedded(object, attributes)
      attributes["_links"] = attributes[:_links] if attributes[:_links]
      attributes["_embedded"] = attributes[:_embedded] if attributes[:_embedded]
      if attributes["_links"]
        attributes["_links"].each do |key, value|
          if value.is_a?(Array)
            object._attributes[key.to_sym] ||= Flexirest::ResultIterator.new
            value.each do |element|
              begin
                embedded_version = attributes["_embedded"][key].detect{|embed| embed["_links"]["self"]["href"] == element["href"]}
                object._attributes[key.to_sym] << new_object(embedded_version, key)
              rescue NoMethodError
                object._attributes[key.to_sym] << Flexirest::LazyAssociationLoader.new(key, element, self)
              end
            end
          else
            begin
              embedded_version = attributes["_embedded"][key]
              object._attributes[key.to_sym] = new_object(embedded_version, key)
            rescue NoMethodError
              object._attributes[key.to_sym] = Flexirest::LazyAssociationLoader.new(key, value, self)
            end
          end
        end
        attributes.delete("_links")
        attributes.delete("_embedded")
      end

      attributes
    end

    private

    def create_object_instance
      return object_is_class? ? @object.new : @object.class.new
    end

    def select_name(name, parent_name)
      if @method[:options][:has_many][name] || @method[:options][:has_one][name]
        return name
      end

      parent_name || name
    end

    def is_json_response?
      @response.response_headers['Content-Type'].nil? || @response.response_headers['Content-Type'].include?('json')
    end

    def is_json_api_response?
      @response.response_headers['Content-Type'] && @response.response_headers['Content-Type'].include?('application/vnd.api+json')
    end

    def is_xml_response?
      @response.response_headers['Content-Type'].include?('xml')
    end

    def generate_new_object(options={})
      if @response.body.is_a?(Array) || @response.body.is_a?(Hash)
        body = @response.body
      elsif is_json_response?
        begin
          body = @response.body.blank? ? {} : MultiJson.load(@response.body)
          body = {} if body.nil?
        rescue MultiJson::ParseError
          raise ResponseParseException.new(status:@response.status, body:@response.body, headers:@response.headers)
        end

        if is_json_api_response?
          body = JsonAPIProxy::Response.parse(body, @object)
        end

        if ignore_root
          [ignore_root].flatten.each do |key|
            body = body[key.to_s] if body.has_key?(key.to_s)
          end
        end
      elsif is_xml_response?
        body = @response.body.blank? ? {} : Crack::XML.parse(@response.body)
        if ignore_root
          [ignore_root].flatten.each do |key|
            body = body[key.to_s] if body.has_key?(key.to_s)
          end
        elsif options[:ignore_xml_root]
          Flexirest::Logger.warn("Using `ignore_xml_root` is deprecated, please switch to `ignore_root`")
          body = body[options[:ignore_xml_root].to_s]
        end
      end
      if translator
        body = begin
          @method[:name].nil? ? body : translator.send(@method[:name], body)
        rescue NoMethodError
          body
        end
      end
      if body.is_a? Array
        result = Flexirest::ResultIterator.new(@response)
        add_nested_body_to_iterator(result, body)
      else
        result = new_object(body, @overridden_name)
        result._status = @response.status
        result._headers = @response.response_headers
        result._etag = @response.response_headers['ETag'] unless @method[:options][:skip_caching]
        if !object_is_class? && options[:mutable] != false
          @object._copy_from(result)
          @object._clean!
          result = @object
        end
      end
      result
    end

    def add_nested_body_to_iterator(result, items)
      items.each do |json_object|
        if json_object.is_a? Hash
          result << new_object(json_object, @overridden_name)
        else
          result << set_corresponding_value(json_object)
        end
      end
    end

    def rubify_name(k)
      k.underscore.to_sym
    end
  end

  class RequestException < StandardError ; end
  class InvalidArgumentsException < StandardError ; end

  class InvalidRequestException < RequestException ; end
  class MissingParametersException < RequestException ; end
  class ResponseParseException < RequestException
    attr_accessor :status, :body, :headers
    def initialize(options)
      @status = options[:status]
      @body = options[:body]
      @headers = options[:headers]
    end
  end

  class HTTPException < RequestException
    attr_accessor :status, :result, :request_url, :body, :raw_response
    def initialize(options)
      @status = options[:status]
      @result = options[:result]
      @request_url = options[:url]
      @body = options[:raw_response]
      @method = options[:method]
    end
    alias_method :body, :raw_response

    def message
      method = @method.try(:upcase)
      "The #{method} to '#{@request_url}' returned a #{@status} status, which raised a #{self.class.to_s} with a body of: #{@body}"
    end

    def to_s
      message
    end
  end
  class HTTPClientException < HTTPException ; end
  class HTTPUnauthorisedClientException < HTTPClientException ; end
  class HTTPBadRequestClientException < HTTPClientException ; end
  class HTTPForbiddenClientException < HTTPClientException ; end
  class HTTPMethodNotAllowedClientException < HTTPClientException ; end
  class HTTPNotAcceptableClientException < HTTPClientException ; end
  class HTTPTimeoutClientException < HTTPClientException ; end
  class HTTPConflictClientException < HTTPClientException ; end
  class HTTPNotFoundClientException < HTTPClientException ; end
  class HTTPTooManyRequestsClientException < HTTPClientException ; end
  class HTTPServerException < HTTPException ; end
  class HTTPInternalServerException < HTTPServerException ; end
  class HTTPNotImplementedServerException < HTTPServerException ; end
  class HTTPBadGatewayServerException < HTTPServerException ; end
  class HTTPServiceUnavailableServerException < HTTPServerException ; end
  class HTTPGatewayTimeoutServerException < HTTPServerException ; end
end
