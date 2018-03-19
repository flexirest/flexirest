# *Flexirest:* Body types

By default Flexirest formats the request bodies as normal CGI parameters in `K=V&K2=V2` format. However, if you want to use JSON for your PUT/POST requests, you can use choose to configure Flexirest to do so (the other option, the default, is `:form_encoded`):

```ruby
class Person < Flexirest::Base
  request_body_type :json
  # ...
end
```

or

```ruby
Flexirest::Base.request_body_type = :json
```

This will also set the header `Content-Type` to `application/x-www-form-urlencoded` by default or `application/json; charset=utf-8` when `:json`. You can override this using the callback `before_request`.

If you have an API that is inconsistent in its body type requirements, you can also specify it on the individual method mapping:

```ruby
class Person < Flexirest::Base
  request_body_type :form_encoded # This is the default, but just for demo purposes

  get :all, '/people', request_body_type: :json
end
```


-----

[< Authentication](authentication.md) | [Parallel requests >](parallel-requests.md)
