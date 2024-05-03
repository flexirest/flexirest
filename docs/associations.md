# *Flexirest:* Associations

There are two types of association. One assumes when you call a method you actually want it to call the method on a separate class (as that class has other methods that are useful). The other is lazy loading related classes from a separate URL.

## Type 1 - Loading Other Classes

If the call would return a single instance or a list of instances that should be considered another object, you can also specify this when mapping the method using the `:has_one` or `:has_many` options respectively. It doesn't call anything on that object except for instantiate it, but it does let you have objects of a different class to the one you initially called.

```ruby
class Expense < Flexirest::Base
  def inc_vat
    ex_vat * 1.20
  end
end

class Address < Flexirest::Base
  def full_string
    "#{self.street}, #{self.city}, #{self.region}, #{self.country}"
  end
end

class Person < Flexirest::Base
  get :find, "/people/:id", :has_many => {:expenses => Expense}, 
    :has_one => {:address => Address}
end

@person = Person.find(1)
puts @person.expenses.reduce {|e| e.inc_vat}
puts @person.address.full_string
```

You can also use `has_one`/`has_many` on the class level to allow chaining of classes. You can specify the class name or allow the system to automatically convert it to the singular class. For example:

```ruby
class Expense < Flexirest::Base
  def inc_vat
    ex_vat * 1.20
  end
end

class Address < Flexirest::Base
  def full_string
    "#{self.street}, #{self.city}, #{self.region}, #{self.country}"
  end
end

class Person < Flexirest::Base
  has_one :addresses
  has_many :expenses, Expense
  get :find, "/people/:id"
end

class Company < Flexirest::Base
  has_many :people
  get :find, "/companies/:id"
end
```

Sometimes we want attributes to just return a simple Ruby Array. To achieve this we can add an `:array` option to the method. This is especially useful when the attribute contains an array of scalar values. If you don't specify the `:array` option Flexirest will return a `Flexirest::ResultIterator`. To illustrate the difference consider the following example:

```ruby
class Book < Flexirest::Base
  # :authors attribute ["Robert T. Kiyosaki", "Sharon L. Lechter C.P.A"]
  # :genres attribute ["self-help", "finance", "education"]
  get :find, "/books/:name", array: [:authors]
end
```

In the example above, the following results can be observed:

```ruby
@book = Book.find("rich-dad-poor-dad")
puts @book.authors
#=> ["Robert T. Kiyosaki", "Sharon L. Lechter C.P.A"]
puts @book.authors.class
#=> Array
puts @book.genres
#=> #<Flexirest::ResultIterator:0x007ff420fe7a88 @_status=nil, @_headers=nil, @items=["self-help", "finance", "education"]>
puts @books.genres.class
#=> Flexirest::ResultIterator
puts @books.genres.items
#=> ["self-help", "finance", "education"]
```

When the `:array` option includes an attribute, it is assumed the values were returned with the request, and they will not be lazily loaded. It is also assumed the attribute values do not map to a Flexirest resource.

## Type 2 - Lazy Loading From Other URLs

If the call for an attribute should

+ Use the value held within the specified attribute as a URL(s) from which to load the associated resource(s)
+ **THEN**, create an instance of your API object from the result
+ **THEN**, call subsequent chained methods on that instance

you can specify this when mapping the method by passing attribtues to the `:lazy` option.

```ruby
class Book < Flexirest::Base
  get :find, "/books/:name"
end

class Person < Flexirest::Base
  get :find, "/people/:id", :lazy => { books: Book }
end
```

Use it like this:

```ruby
# Makes a call to /people/1
@person = Person.find(1)

# Lazily makes a call to the first URL found in the "books":[...] array in the Person.find response
# - Only makes the HTTP request when first used
# - Instantiates a Book object from the response and then accesses its "name" property
@person.books.first.name
```

### URLs in API responses
To provide a URL(s) for lazy loading an attribute, the API response may contain one of the following for the attribute (**`book`** or **`books`** is the attribute in all examples below):

```ruby
# all of the following will lazy load a single object from the specified URL
"book" : "https://example.com/books/1"
# or
"book" : { "url" : "https://example.com/books/1"}
# or
"book" : { "href" : "https://example.com/books/1"}

# books will be an array whose elements will be lazy loaded one-by-one, from the URL in the corresponding array position, whenever each element is first accessed
"books" : ["https://example.com/books/1", "https://example.com/books/2"]

# book will be an object where the values will be lazy loaded one-by-one, from the URL in the corresponding key, whenever each key is first accessed (e.g. the first time object.book.author is accessed)
"book" : { "author" : "https://example.com/author/1"}
```

It is required that each URL is a complete URL including a protocol starting with `http`.

## Type 3 - HAL Auto-loaded Resources

You don't need to define lazy attributes if they are defined using [HAL](http://stateless.co/hal_specification.html) (with an optional embedded representation). If your resource has an `_links` item (and optionally an `_embedded` item) then it will automatically treat the linked resources (with the `_embedded` cache) as if they were defined using `:lazy` as per type 2 above.

If you need to, you can access properties of the HAL association. By default just using the HAL association gets the embedded resource (or requests the remote resource if not available in the `_embedded` list).

```ruby
@person = Person.find(1)
@person.students[0]._hal_attributes("title")
```

## Type 4 - Nested Resources

It's common to have resources that are logically children of other resources. For example, suppose that your API includes these endpoints:

| HTTP Verb | Path                        |                                          |
|-----------|-----------------------------|------------------------------------------|
| POST      | /magazines/:magazine_id/ads | create a new ad belonging to a magazine  |
| GET       | /magazines/:magazine_id/ads | display a list of all ads for a magazine |

In these cases, your child class will contain the following:

```ruby
class Ad < Flexirest::Base
  post :create, "/magazines/:magazine_id/ads"
  get :all, "/magazines/:magazine_id/ads"
end
```

You can then access Ads by specifying their magazine IDs:

```ruby
Ad.all(magazine_id: 1)
Ad.create(magazine_id: 1, title: "My Add Title")
```

## Type 5 - JSON API Auto-loaded Resources

If attributes are defined using [JSON API](http://jsonapi.org), you don't need to define lazy attributes. If your resource has a `links` object with a `related` item, it will automatically treat the linked resources as if they were defined using `:lazy`.

You need to activate JSON API by specifying the `json_api` proxy:

```ruby
class Article < Flexirest::Base
  proxy :json_api
end
```

If you want to embed linked resources directly in the response (i.e. request a JSON API compound document), use the `includes` class method. The linked resource is accessed in the same was as if it was lazily loaded, but without the extra request:

```ruby
# Makes a call to /articles with parameters: include=images
Article.includes(:images).all

# For nested resources, the include parameter becomes: include=images.tags,images.photographer
Article.includes(:images => [:tags, :photographer]).all
```


-----

[< Faraday configuration](faraday-configuration.md) | [Combined example >](combined-example.md)
