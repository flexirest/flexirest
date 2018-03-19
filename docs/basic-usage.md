# *Flexirest:* Basic usage

First you need to create your new model class `app/models/person.rb`:

```ruby
class Person < Flexirest::Base
  base_url "https://www.example.com/api/v1"

  get :all, "/people"
  get :find, "/people/:id"
  put :save, "/people/:id"
  post :create, "/people"
  delete :remove, "/people/:id"
end
```

Note I've specified the `base_url` in the class above. This is useful where you want to be explicit or use different APIs for some classes and be explicit. If you have one server that's generally used, you can set it once with a simple line in a `config/initializer/{something}.rb` file:

```ruby
Flexirest::Base.base_url = "https://www.example.com/api/v1"
```

Any `base_url` settings in specific classes override this declared default. You can also assign an array of URLs to `base_url` and Flexirest will randomly pull one of the URLs for each request, giving you a very simplistic load balancing (it doesn't know about the health or load levels of the backends).

You can then use your new class like this:

```ruby
# Create a new person
@person = Person.create(
  first_name:"John"
  last_name:"Smith"
)

# Find a person (not needed after creating)
id = @person.id
@person = Person.find(id)

# Update a person
@person.last_name = "Jones"
@person.save

# Get all people
@people = Person.all
@people.each do |person|
  puts "Hi " + person.first_name
end
```

For `delete` requests whether an API can handle a body or not is undefined. The default is to ignore any parameters not sent in the URL named parameters, but you can optionally specify `send_delete_body` and it will encode them in your chosen way into the body.

```
  delete :remove, "/people/:id", send_delete_body: true
```

If an API returns an array of results and you have [will_paginate](https://rubygems.org/gems/will_paginate) installed then you can call the paginate method to return a particular page of the results (note: this doesn't reduce the load on the server, but it can help with pagination if you have a cached response).

```ruby
@people = Person.all
@people.paginate(page: 1, per_page: 10).each do |person|
  puts "You made the first page: " + person.first_name
end
```

Note, you can assign to any attribute, whether it exists or not before and read from any attribute (which will return nil if not found). If you pass a string or a number to a method it will assume that it's for the "id" field. Any other field values must be passed as a hash and you can't mix passing a string/number and a hash.

```ruby
@person = Person.find(1234)  # valid
@person = Person.find("1234")  # valid
@person = Person.find(:id => 1234)  # valid
@person = Person.find(:id => 1234, :name => "Billy")  # valid
@person = Person.find(1234, :name => "Billy")  # invalid
```

You can also call any mapped method as an instance variable which will pass the current attribute set in as parameters (either GET or POST depending on the mapped method type). If the method returns a single instance it will assign the attributes of the calling object and return itself. If the method returns a list of instances, it will only return the list. So, we could rewrite the create call above as:

```ruby
@person = Person.new
@person.first_name = "John"
@person.last_name  = "Smith"
@person.create
puts @person.id
```

The response of the #create call set the attributes at that point (any manually set attributes before that point are removed).

If you have attributes beginning with a number, Ruby doesn't like this. So, you can use hash style notation to read/write the attributes:

```ruby
@tv = Tv.find(model:"UE55U8000") # { "properties" : {"3d" : false} }
puts @tv.properties["3d"]
@tv.properties["3d"] = true
```

If you want to debug the response, using inspect on the response object may well be useful. However, if you want a simpler output, then you can call `#to_json` on the response object:

```ruby
@person = Person.find(email:"something@example.com")
puts @person.to_json
```

-----

[< Introduction](../README.md) | [Ruby on Rails integration >](ruby-on-rails-integration.md)
