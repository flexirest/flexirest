require 'active_support/all'
require "flexirest/version"
require "flexirest/attribute_parsing"
require "flexirest/active_model_form_support"
require "flexirest/associations"
require "flexirest/mapping"
require "flexirest/caching"
require "flexirest/logger"
require "flexirest/configuration"
require "flexirest/connection"
require "flexirest/connection_manager"
require "flexirest/instrumentation"
require "flexirest/result_iterator"
require "flexirest/headers_list"
require "flexirest/lazy_loader"
require "flexirest/lazy_association_loader"
require "flexirest/multipart"
require "flexirest/json_api_proxy"
require "flexirest/request"
require "flexirest/request_delegator"
require "flexirest/validation"
require "flexirest/callbacks"
require "flexirest/proxy_base"
require "flexirest/recording"
require "flexirest/base_without_validation"
require "flexirest/base"
require "flexirest/monkey_patching"
require "flexirest/plain_response"

module Flexirest
  @@name = "Flexirest"

  def self.name
    @@name
  end
  def self.name=(value)
    @@name = value
  end

  class NoAttributeException < StandardError ; end
  class ValidationFailedException < StandardError ; end
  class MissingOptionalLibraryError < StandardError ; end
end
