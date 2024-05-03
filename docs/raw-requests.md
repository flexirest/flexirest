# *Flexirest:* Raw requests

Sometimes you have a URL that you just want to force through, but have the response handled in the same way as normal objects or you want to have the callbacks run (say for authentication). The easiest way to do that is to call `_request` on the class:

```ruby
class Person < Flexirest::Base
end

people = Person._request('http://api.example.com/v1/people') # Defaults to get with no parameters
# people is a normal Flexirest object, implementing iteration, HAL loading, etc.

Person._request('http://api.example.com/v1/people', :post, {id:1234,name:"John"}) # Post with parameters
```

When you need to specify custom headers (for example for authentication) you can do this with a fourth option to the `_request` method. If you are using the default parameters you'll need to specify them. For example:

```ruby
Person._request("http://api.example.com/v1/people", :get, {}, {headers:{"X-Something": "foo/bar"}})
```

If you want to use a lazy loaded request instead (so it will create an object that will only call the API if you use it), you can use `_lazy_request` instead of `_request`. If you want you can create a construct that creates and object that lazy loads itself from a given method (rather than a URL):

```ruby
@person = Person._lazy_request(Person._request_for(:find, 1234))
```

This initially creates a `Flexirest::Request` object as if you'd called `Person.find(1234)` which is then passed in to the `_lazy_request` method to return an object that will call the request if any properties are actually used. This may be useful at some point, but it's actually easier to just prefix the `find` method call with `lazy_` like:

```ruby
@person = Person.lazy_find(1234)
```

Doing this will try to find a literally mapped method called "lazy_find" and if it fails, it will try to use "find" but instantiate the object lazily.


-----

[< Automatic conversion of fields to Date/DateTime](automatic-conversion-of-fields-to-datedatetime.md) | [Plain requests >](plain-requests.md)
