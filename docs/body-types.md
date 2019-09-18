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

You can also use `:form_multipart` if your API requires file uploads. Any parameters set to `File` like object (supporting `#path` and `#read`) will be automatically uploaded with the parameters, in a normal form submission style:

```ruby
class Person < Flexirest::Base
  request_body_type :form_multipart
  put :update, "/people/:id"
end

Person.update(id: 1, avatar: File.open("avatar.png"))
```

If you have an API that is inconsistent in its body type requirements, you can also specify it on the individual method mapping:

```ruby
class Person < Flexirest::Base
  request_body_type :form_encoded # This is the default, but just for demo purposes

  get :all, '/people', request_body_type: :json
end
```

If your API expects some weird formatting on the requests, but you still want to use Flexirest for caching, response parsing, other models, etc you can pass `:plain` as the request body type either at the class level or method mapping level, and this will be passed through to the API. By default `plain` requests are sent with the `Content-Type: text/plain` header, but you can override this with `:content_type` when calling the mapped method.

```ruby
class Person < Flexirest::Base
  put :save, '/person/:id/logs', request_body_type: :plain
end

Person.save(id: 1, body: '["Something here"]', 
            content_type: "application/json")
```

-----

[< Authentication](authentication.md) | [Parallel requests >](parallel-requests.md)
