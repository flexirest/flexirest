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

You can also pass in a Proc or a block to `username` and `password` if you want to dynamically pull it from somewhere, e.g. a [Current class descending from ActiveSupport::CurrentAttributes](http://edgeapi.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html).

```ruby
class Person < Flexirest::Base
  username -> (obj) { obj ? Account.find(obj.id).username : Current.username }
  password do
    Rails.configuration.x.default_password
  end

  get :all, "/people"
  get :find, "/people/:id"
end
```

Note in the above code sample, we've used a proc in one of them and a block in the other. There's no difference at all, we just wanted to demonstrate both syntaxes. Also, both will accept a single parameter (`obj` in the above) to receive an optional parameter for the current Flexirest object (if not called from a class context). For example, the `username` call above handles things differently if it's called from an object context:

```ruby
person = Person.new(id: 1234)
person.find
```

Or if it's called from a class context:

```ruby
Person.find(id: 1234)
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
