require 'spec_helper'

describe Flexirest::Configuration do
  before :each do
    Object.send(:remove_const, :ConfigurationExample) if defined?(ConfigurationExample)
    Object.send(:remove_const, :SubConfigurationExample) if defined?(SubConfigurationExample)
    Flexirest::Base._reset_configuration!

    class ConfigurationExample
      include Flexirest::Configuration
      base_url "http://www.example.com"
      username "john"
      password "smith"
      request_body_type :json
    end

    class SubConfigurationExample < ConfigurationExample
    end

    class ConfigurationExampleBare
      include Flexirest::Configuration
    end
  end

  it "should default to non-whiny missing methods" do
    class UnusuedConfigurationExample1
      include Flexirest::Configuration
    end
    expect(UnusuedConfigurationExample1.whiny_missing).to be_falsey
  end

  it "should allow whiny missing methods to be enabled" do
    ConfigurationExample.whiny_missing true
    expect(ConfigurationExample.whiny_missing).to be_truthy
  end

  it "should remember the set base_url" do
    expect(ConfigurationExample.base_url).to eq("http://www.example.com")
  end

  it "should remember the set base_url on a class, overriding a general one" do
    Flexirest::Base.base_url = "http://general.example.com"
    expect(ConfigurationExample.base_url).to eq("http://www.example.com")
  end

  it "should remember the set base_url on a class, overriding a general one" do
    expect(SubConfigurationExample.base_url).to eq("http://www.example.com")
  end

  it "should remove a trailing slash from a globally configured base_url" do
    Flexirest::Base.base_url = "http://general.example.com/"
    expect(ConfigurationExample.base_url).to eq("http://www.example.com")
    Flexirest::Base.base_url = ""
  end

  it "should remember the set base_url on the base class if a more specific one hasn't been set" do
    Flexirest::Base.base_url = "http://general.example.com"
    expect(ConfigurationExampleBare.base_url).to eq("http://general.example.com")
    Flexirest::Base.base_url = ""
  end

  it "should remove a trailing slash from a specific class configured base_url" do
    class ConfigurationExample2
      include Flexirest::Configuration
      base_url "http://specific.example.com/"
    end
    expect(ConfigurationExample2.base_url).to eq("http://specific.example.com")
  end

  it "should remember the set username" do
    expect(ConfigurationExample.username).to eq("john")
  end

  it "should remember the set username on a class, overriding a general one" do
    Flexirest::Base.username = "bill"
    expect(ConfigurationExample.username).to eq("john")
    Flexirest::Base.username = nil
  end

  it "should remember the set username on a class, overriding a general one" do
    expect(SubConfigurationExample.username).to eq("john")
  end

  it "should escape the username" do
    Flexirest::Base.username = "bill@example.com"
    expect(Flexirest::Base.username).to eq("bill%40example.com")
    Flexirest::Base.username = nil
  end

  it "should not doubly escape the username" do
    Flexirest::Base.username = "bill%40example.com"
    expect(Flexirest::Base.username).to_not eq("bill%2540example.com")
    Flexirest::Base.username = nil
  end

  it "should remember the set password" do
    expect(ConfigurationExample.password).to eq("smith")
  end

  it "should remember the set password on a class, overriding a general one" do
    Flexirest::Base.password = "bloggs"
    expect(ConfigurationExample.password).to eq("smith")
    Flexirest::Base.password = nil
  end

  it "should remember the set password on a class, overriding a general one" do
    expect(SubConfigurationExample.password).to eq("smith")
  end

  it "should escape the password" do
    Flexirest::Base.password = "something@else"
    expect(Flexirest::Base.password).to eq("something%40else")
    Flexirest::Base.password = nil
  end

  it "should not doubly escape the password" do
    Flexirest::Base.password = "something%40else"
    expect(Flexirest::Base.password).to_not eq("something%2540else")
    Flexirest::Base.password = nil
  end

  it "should default to a form_encoded request_body_type" do
    expect(Flexirest::Base.request_body_type).to eq(:form_encoded)
  end

  it "should remember the request_body_type" do
    expect(ConfigurationExample.request_body_type).to eq(:json)
  end

  it "should remember the set request_body_type on a class, overriding a general one" do
    Flexirest::Base.request_body_type = :unknown
    expect(Flexirest::Base.request_body_type).to eq(:unknown)
    expect(ConfigurationExample.request_body_type).to eq(:json)
  end

  it "should remember the set username on a class, overriding a general one" do
    expect(SubConfigurationExample.request_body_type).to eq(:json)
  end

  it "should default to non-lazy loading" do
    class LazyLoadingConfigurationExample1
      include Flexirest::Configuration
    end
    expect(LazyLoadingConfigurationExample1.lazy_load?).to be_falsey
  end

  it "should be able to switch on lazy loading" do
    class LazyLoadingConfigurationExample2
      include Flexirest::Configuration
      lazy_load!
    end
    expect(LazyLoadingConfigurationExample2.lazy_load?).to be_truthy
  end

  describe 'api auth' do
    context 'default' do
      it "should be false using_api_auth?" do
        expect(Flexirest::Base.using_api_auth?).to be_falsey
      end

      it "should raise Flexirest::MissingOptionalLibraryError if api-auth isn't installed" do
        expect(ConfigurationExample).to receive(:require).with("api-auth").and_raise(LoadError)
        expect {
          ConfigurationExample.api_auth_credentials('id123', 'secret123', digest: "sha256")
        }.to raise_error(Flexirest::MissingOptionalLibraryError)
      end
    end

    context 'setting api auth credentials' do
      before(:each) do
        ConfigurationExample.api_auth_credentials('id123', 'secret123', digest: "sha256")
      end

      it "should remember setting using_api_auth?" do
        expect(ConfigurationExample.using_api_auth?).to be_truthy
      end

      it "should remember setting api_auth_access_id" do
        expect(ConfigurationExample.api_auth_access_id).to eq('id123')
      end

      it "should remember setting api_auth_secret_key" do
        expect(ConfigurationExample.api_auth_secret_key).to eq('secret123')
      end

      it "should remember setting api_auth_options" do
        expect(ConfigurationExample.api_auth_options).to eq({digest: "sha256"})
      end

      it "should return an empty hash for api_auth_options if it got reset to nil" do
        ConfigurationExample.instance_variable_set(:@api_auth_options, nil)
        expect(ConfigurationExample.api_auth_options).to eq({})
      end

      it "should inherit api_auth_credentials when not set" do
        class ConfigurationExtension < ConfigurationExample
        end
        expect(ConfigurationExtension.api_auth_access_id).to eq('id123')
        expect(ConfigurationExtension.api_auth_secret_key).to eq('secret123')
      end

      it "should override inherited api_auth_credentials when set" do
        class ConfigurationExtension2 < ConfigurationExample
        end
        ConfigurationExtension2.api_auth_credentials('id456', 'secret456')
        expect(ConfigurationExtension2.api_auth_access_id).to eq('id456')
        expect(ConfigurationExtension2.api_auth_secret_key).to eq('secret456')
      end
    end
  end

  it "should default to non-verbose logging" do
    class VerboseConfigurationExample1
      include Flexirest::Configuration
    end
    expect(VerboseConfigurationExample1.verbose).to be_falsey
  end

  it "should be able to switch on verbose logging" do
    class VerboseConfigurationExample2
      include Flexirest::Configuration
      verbose!
    end
    class VerboseConfigurationExample3
      include Flexirest::Configuration
      verbose true
    end
    expect(VerboseConfigurationExample2.verbose).to be_truthy
    expect(VerboseConfigurationExample3.verbose).to be_truthy
  end

  it "should store a translator given" do
    expect{ ConfigurationExample.send(:translator) }.to_not raise_error
    ConfigurationExample.send(:translator, String.new)
    expect(ConfigurationExample.translator).to respond_to(:length)
  end

  it "should store a proxy given" do
    expect{ ConfigurationExample.send(:proxy) }.to_not raise_error
    ConfigurationExample.send(:proxy, String.new)
    expect(ConfigurationExample.proxy).to respond_to(:length)
  end

  describe "faraday_config" do
    let(:faraday_double){double(:faraday).as_null_object}

    it "should use default adapter if no other block set" do
      expect(faraday_double).to receive(:adapter).with(Faraday.default_adapter)
      ConfigurationExample.faraday_config.call(faraday_double)
    end

    it "should us set adapter if no other block set" do
      ConfigurationExample.adapter = :net_http

      expect(faraday_double).to receive(:adapter).with(:net_http)

      ConfigurationExample.faraday_config.call(faraday_double)
    end

    it "should use the adapter of the passed in faraday_config block" do
      ConfigurationExample.faraday_config {|faraday| faraday.adapter(:rack)}

      expect(faraday_double).to receive(:adapter).with(:rack)

      ConfigurationExample.faraday_config.call(faraday_double)
    end
  end

end
