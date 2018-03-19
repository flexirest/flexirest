# *Flexirest:* Filtering result lists

If the API returns a JSON list of items, this is retured to you as a `Flexirest::ResultIterator` object. A `ResultIterator` sorts simple filtering of the list using a `where` method based on values matching a specified criteria (or matching using regular expressions):

```ruby
class Article < Flexirest::Base
  get :all, "/articles"
end

Article.all.where(published: true, department: /technical\-/)
```


-----

[< Validation](validation.md) | [Debugging >](debugging.md)
