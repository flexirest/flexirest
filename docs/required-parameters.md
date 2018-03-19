# *Flexirest:* Required parameters

If you want to specify that certain parameters are required for a specific call, you can specify them like:

```ruby
class Person < Flexirest::Base
  get :all, '/people', :requires => [:active]
end

@people = Person.all # raises Flexirest::MissingParametersException
@people = Person.all(active:false)
```


-----

[< Root elements](root-elements.md) | [Updating only changed/dirty attributes >](updating-only-changed-dirty-attributes.md)
