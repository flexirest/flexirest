# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flexirest/version'

Gem::Specification.new do |spec|
  spec.name                  = "flexirest"
  spec.version               = Flexirest::VERSION
  spec.required_ruby_version = ">= 3.0.0"
  spec.platform              = Gem::Platform::RUBY
  spec.authors               = ["Andy Jeffries"]
  spec.email                 = ["andy@andyjeffries.co.uk"]
  spec.description           = %q{Accessing REST services in a flexible way}
  spec.summary               = %q{This gem is for accessing REST services in a flexible way.  ActiveResource already exists for this, but it doesn't work where the resource naming doesn't follow Rails conventions, it doesn't have in-built caching and it's not as flexible in general.}
  spec.homepage              = "https://andyjeffries.co.uk/"
  spec.license               = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["source_code_uri"] = "https://github.com/flexirest/flexirest"
  end

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-rcov"
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency "api-auth", ">= 2.4"
  spec.add_development_dependency 'faraday-typhoeus'
  spec.add_development_dependency 'activemodel'
  spec.add_development_dependency 'rest-client'
  spec.add_development_dependency 'timecop'

  spec.add_runtime_dependency "mime-types"
  spec.add_runtime_dependency "multi_json"
  spec.add_runtime_dependency "crack"
  spec.add_runtime_dependency "faraday", "~> 2.7"

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "actionpack"
end
