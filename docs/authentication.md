# *Flexirest:* Authentication

## Basic authentication

You can authenticate with Basic authentication by putting the username and password in to the `base_url` or by setting them within the specific model:

```ruby
class Person < Flexirest::Base
  username 'api'
  password 'eb693ec-8252c-d6301-02fd0-d0fb7-c3485'

  # ...
end
```

## Api-Auth

Using the [Api-Auth](https://github.com/mgomes/api_auth) integration it is very easy to sign requests. Include the Api-Auth gem in your `Gemfile` and  then add it to your application. Then simply configure Api-Auth one time in your app and all requests will be signed from then on.

```ruby
require 'api-auth'

@access_id = '123456'
@secret_key = 'abcdef'
Flexirest::Base.api_auth_credentials(@access_id, @secret_key)
```

You can also specify different credentials for different models just like configuring `base_url`:

```ruby
class Person < Flexirest::Base
  api_auth_credentials '123456', 'abcdef'
end
```

For more information on how to generate an access id and secret key please read the [Api-Auth](https://github.com/mgomes/api_auth) documentation.

If you want to specify either the `:digest` or `:override_http_method` to ApiAuth, you can pass these in as options after the access ID and secret key, for example:

```ruby
class Person < Flexirest::Base
  api_auth_credentials '123456', 'abcdef', digest: "sha256"
end
```


-----

[< Lazy loading](lazy-loading.md) | [Body types >](body-types.md)
