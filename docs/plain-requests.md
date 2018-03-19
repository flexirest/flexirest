# *Flexirest:* Plain requests

If you are already using Flexirest but then want to simply call a normal URL and receive the resulting content as a string (i.e. not going through JSON parsing or instantiating in to a `Flexirest::Base` descendent) you can use code like this:

```ruby
class Person < Flexirest::Base
end

people = Person._plain_request('http://api.example.com/v1/people') # Defaults to get with no parameters
# people is a normal Flexirest object, implementing iteration, HAL loading, etc.

Person._plain_request('http://api.example.com/v1/people', :post, {id:1234,name:"John"}) # Post with parameters
```

The parameters are the same as for `_request`, but it does no parsing on the response

You can also bypass the response parsing using a mapped method like this:

```ruby
class Person < Flexirest::Base
  get :all, "/v1/people", plain: true
end
```

The response of a plain request (from either source) is a `Flexirest::PlainResponse` which acts like a string containing the response's body, but it also has a `_headers` method that returns the HTTP response headers and a `_status` method containing the response's HTTP method.


-----

[< Raw requests](raw-requests.md) | [JSON API >](json-api.md)
