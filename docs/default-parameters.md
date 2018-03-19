# *Flexirest:* Default parameters

If you want to specify default parameters you shouldn't use a path like:

```ruby
class Person < Flexirest::Base
  get :all, '/people?all=true' # THIS IS WRONG!!!
end
```

You should use a defaults option to specify the defaults, then they will be correctly overwritten when making the request

```ruby
class Person < Flexirest::Base
  get :all, '/people', :defaults => {:active => true}
end

@people = Person.all(active:false)
```

If you specify `defaults` as a `Proc` this will be executed with the set parameters (which you can change). For example to allow you to specify a reference (but the API wants it formated as "id-reference") you could use:

```ruby
class Person < Flexirest::Base
  get :all, "/", defaults: (Proc.new do |params|
    reference = params.delete(:reference) # Delete the old parameter
    {
      id: "id-#{reference}"
    } # The last thing is the hash of defaults
  end)
end
```


-----

[< Translating APIs](translating-apis.md) | [Root elements >](root-elements.md)
