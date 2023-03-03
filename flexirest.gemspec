# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flexirest/version'

Gem::Specification.new do |spec|
  spec.name          = "flexirest"
  spec.version       = Flexirest::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Andy Jeffries"]
  spec.email         = ["andy@andyjeffries.co.uk"]
  spec.description   = %q{Accessing REST services in a flexible way}
  spec.summary       = %q{This gem is for accessing REST services in a flexible way.  ActiveResource already exists for this, but it doesn't work where the resource naming doesn't follow Rails conventions, it doesn't have in-built caching and it's not as flexible in general.}
  spec.homepage      = "https://andyjeffries.co.uk/"
  spec.license       = "MIT"

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
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.1.0')
    spec.add_development_dependency "webmock", "~> 2.1.0"
    spec.add_development_dependency "rspec_junit_formatter", "= 0.2.3"
  else
    spec.add_development_dependency "webmock"
    spec.add_development_dependency "rspec_junit_formatter"
  end
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-rcov"
  spec.add_development_dependency 'coveralls'
  ruby_below_2_7_0 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7.0')
  if ruby_below_2_7_0
    spec.add_development_dependency "api-auth", ">= 1.3.1", "< 2.4"
    spec.add_development_dependency 'typhoeus'
  else
    spec.add_development_dependency "api-auth", ">= 2.4"
    spec.add_development_dependency 'faraday-typhoeus'
  end
  spec.add_development_dependency 'activemodel'
  spec.add_development_dependency 'rest-client'

  spec.add_runtime_dependency "mime-types"
  spec.add_runtime_dependency "multi_json"
  spec.add_runtime_dependency "crack"
  if ruby_below_2_7_0
    spec.add_runtime_dependency "faraday", "~> 1.0"
  else
    spec.add_runtime_dependency "faraday", "~> 2.7"
  end

  # Use Gem::Version to parse the Ruby version for reliable comparison
  # ActiveSupport 5+ requires Ruby 2.2.2
  if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('2.2.2')
    spec.add_runtime_dependency "activesupport"
    spec.add_runtime_dependency "actionpack" unless ruby_below_2_7_0
  else
    spec.add_runtime_dependency "activesupport", "< 5.0.0"
  end
end
