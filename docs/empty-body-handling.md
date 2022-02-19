# *Flexirest:* Empty body handling

If you call a RESTful method that correctly returns a 204 when the request was accepted, but no body is supplied, Flexirest will return `true`. If you call this on an instance of a Flexirest subclass, it will not affect the existing attributes.

```ruby
class Person < Flexirest::Base
  put :save, "/people/:id"
end

p = Person.new(id: "1", name: "Jenny")
saved = p.save
puts saved === true # true
puts p.name # Jenny
```

If your API returns a 200 OK status with an empty body, by default this is handled in the normal way - the attributes are set to an empty set. If you intend to handle it as above for the 204, you can set an extra option on the mapped method like this:

```ruby
class Person < Flexirest::Base
  put :save, "/people/:id", ignore_empty_response: true
end
```

-----

[< Body types](body-types.md) | [Parallel requests >](parallel-requests.md)
