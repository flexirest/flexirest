# *Flexirest:* Combined example

OK, so let's say you have an API for getting articles. Each article has a property called `title` (which is a string) and a property `images` which includes a list of URIs. Following this URI would take you to a image API that returns the image's `filename` and `filesize`. We'll also assume this is a HAL compliant API. We would declare our two models (one for articles and one for images) like the following:

```ruby
class Article < Flexirest::Base
  get :find, '/articles/:id', has_many:{:images => Image} # ,lazy:[:images] isn't needed as we're using HAL
end

class Image < Flexirest::Base
  # You may have mappings here

  def nice_size
    "#{size/1024}KB"
  end
end
```

We assume the /articles/:id call returns something like the following:

```json
{
  "title": "Fly Fishing",
  "author": "J R Hartley",
  "images": [
    "http://api.example.com/images/1",
    "http://api.example.com/images/2"
  ]
}
```

We said above that the /images/:id call would return something like:

```json
{
  "filename": "http://cdn.example.com/images/foo.jpg",
  "filesize": 123456
}
```

When it comes time to use it, you would do something like this:

```ruby
@article = Article.find(1)
@article.images.is_a?(Flexirest::LazyAssociationLoader)
@article.images.size == 2
@article.images.each do |image|
  puts image.inspect
end
```

At this point, only the HTTP call to '/articles/1' has been made. When you actually start using properties of the images list/image object then it makes a call to the URL given in the images list and you can use the properties as if it was a nested JSON object in the original response instead of just a URL:

```ruby
@image = @article.images.first
puts @image.filename
# => http://cdn.example.com/images/foo.jpg
puts @image.filesize
# => 123456
```

You can also treat `@image` looks like an Image class (and you should 100% treat it as one) it's technically a lazy loading proxy. So, if you cache the views for your application should only make HTTP API requests when actually necessary.

```ruby
puts @image.nice_size
# => 121KB
```


-----

[< Associations](associations.md) | [Caching >](caching.md)
