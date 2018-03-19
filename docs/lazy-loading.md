# *Flexirest:* Lazy loading

Flexirest supports lazy loading (delaying the actual API call until the response is actually used, so that views can be cached without still causing API calls).

**Note: Currently this isn't enabled by default, but this is likely to change in the future to make lazy loading the default.**

To enable it, simply call the lazy_load! method in your class definition:

```ruby
class Article < Flexirest::Base
  lazy_load!
end
```

If you have a ResultIterator that has multiple objects, each being lazy loaded or HAL linked resources that isn't loaded until it's used, you can actually parallelise the fetching of the items using code like this:

```ruby
items.parallelise(:id)

# or

items.parallelise do |item|
  item.id
end
```

This will return an array of the named method for each object or the response from the block and will have loaded the objects in to the resource.

-----

[< Using callbacks](using-callbacks.md) | [Authentication >](authentication.md)
