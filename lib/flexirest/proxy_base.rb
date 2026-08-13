require "uri"

module Flexirest
  class ProxyBase
    module ClassMethods
      # Per-request state used while handling a proxied request is stored in
      # thread-local storage (keyed by the proxy class) rather than on the
      # class itself. The DSL is implemented as class methods run via
      # class_eval, so historically "the current request" was stored in class
      # instance variables/class variables, which are shared across every
      # thread calling through the same proxy class. That caused request data
      # to be dropped or corrupted under concurrency. Keeping it per-thread
      # isolates concurrent requests while preserving the existing DSL.
      def _proxy_state
        states = (Thread.current[:flexirest_proxy_state] ||= {})
        states[self] ||= {}
      end
      def get(match, &block)
        add_mapping(:get, match, block)
      end

      def post(match, &block)
        add_mapping(:post, match, block)
      end

      def put(match, &block)
        add_mapping(:put, match, block)
      end

      def patch(match, &block)
        add_mapping(:patch, match, block)
      end

      def delete(match, &block)
        add_mapping(:delete, match, block)
      end

      def add_mapping(method_type, match, block)
        @mappings ||= []

        if match.is_a?(String) && (param_keys = match.scan(/:\w+/)) && param_keys.any?
          # Build the pattern from a copy rather than mutating the caller's string. A
          # route is almost always declared with a string literal, and under Ruby 3.4+
          # those are chilled (mutating one warns); with frozen string literals enabled
          # - Ruby 4.0's --enable=frozen-string-literal, or a magic comment - the same
          # mutation raises FrozenError and the proxy class fails to load.
          pattern = param_keys.reduce(match.dup) { |acc, key| acc.gsub(key, "([^/]+)") }
          param_keys = param_keys.map {|k| k.gsub(":", "").to_sym}
          match = Regexp.new(pattern)
        end

        @mappings << OpenStruct.new(http_method:method_type, match:match, block:block, param_keys:param_keys)
      end

      def body(value = nil)
        _proxy_state[:body] = value if value
        _proxy_state[:body]
      end

      def url(value = nil)
        _proxy_state[:url] = value if value
        _proxy_state[:url]
      end

      def get_params(value = nil)
        _proxy_state[:get_params] = value if value
        _proxy_state[:get_params]
      end

      def post_params(value = nil)
        _proxy_state[:post_params] = value if value
        _proxy_state[:post_params]
      end

      def params(value = nil)
        _proxy_state[:params] = value if value
        _proxy_state[:params]
      end

      def passthrough
        rebuild_request
        state = _proxy_state
        state[:original_handler].call(state[:request])
      end

      def result_is_json_or_unspecified?(result)
        result.headers['Content-Type'].include?('json')
      rescue
        true
      end

      def translate(result, options = {})
        incoming_content_type = result.headers['Content-Type']
        if result_is_json_or_unspecified?(result)
          result.headers["content-type"] = "application/hal+json"
        end
        result = FaradayResponseProxy.new(OpenStruct.new(status:result.status, response_headers:result.headers, body:result.body))
        if result.body.present?
          if incoming_content_type && incoming_content_type["xml"]
            result.body = yield Crack::XML.parse(result.body)
          else
            result.body = yield MultiJson.load(result.body)
          end
        end
        result
      end

      def rebuild_request
        state = _proxy_state
        request = state[:request]
        if state[:url] != state[:original_url]
          request.forced_url = request.url = state[:url]
        end
        if state[:body] != state[:original_body]
          request.body = state[:body]
        elsif state[:post_params] != state[:original_post_params]
          request.body = nil
          request.prepare_request_body(state[:post_params])
        end
        if state[:get_params] != state[:original_get_params]
          request.get_params = state[:get_params]
          request.prepare_url
          request.append_get_parameters
        end
      end

      def handle(request, &block)
        # Preserve any state already in flight on this thread (e.g. a proxied
        # request that itself triggers another request through the same proxy
        # class) and restore it when we're done, so nested calls can't clobber
        # each other.
        states = (Thread.current[:flexirest_proxy_state] ||= {})
        previous_state = states[self]

        state = states[self] = {}
        state[:request] = request
        state[:original_handler] = block

        state[:original_body] = request.body
        state[:body] = state[:original_body].dup

        state[:original_get_params] = request.get_params
        state[:get_params] = state[:original_get_params].dup

        state[:original_post_params] = request.post_params
        state[:post_params] = (state[:original_post_params] || {}).dup

        state[:original_url] = request.url
        state[:url] = state[:original_url].dup

        if mapping = find_mapping_for_current_request
          self.class_eval(&mapping.block)
        else
          passthrough
        end
      ensure
        if previous_state
          states[self] = previous_state
        else
          states.delete(self)
        end
      end

      def find_mapping_for_current_request
        state = _proxy_state
        uri = URI.parse(state[:original_url])
        @mappings ||= []
        state[:params] = {}
        @mappings.each do |mapping|
          match = mapping.match
          if (match_data = uri.path.match(match)) && state[:request].http_method.to_sym == mapping.http_method
            matches = match_data.to_a
            matches.shift
            matches.each_with_index do |value, index|
              state[:params][mapping.param_keys[index]] = value
            end
            return mapping
          end
        end
        nil
      end

      def render(body, status=200, content_type="application/javascript", headers={})
        headers["Content-type"] = content_type
        FaradayResponseProxy.new(OpenStruct.new(body:body, status:status, response_headers:headers, proxied:true))
      end
    end

    def self.inherited(base)
      base.extend(ClassMethods)
    end
  end

  # FaradayResponseProxy acts just like a Faraday Response object,
  # however it always resolves the request immediately regardless of
  # whether it is inside an in_parallel block or not
  class FaradayResponseProxy
    def initialize(response)
      @response = response
    end

    def headers
      @response.response_headers
    end

    def status
      @response.status
    end

    def body
      @response.body
    end

    def body=(value)
      @response.body = value
      value
    end

    def on_complete
      yield(@response)
    end

    def finished?
      true
    end
  end
end
