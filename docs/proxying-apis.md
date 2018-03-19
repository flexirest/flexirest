# *Flexirest:* Proxying APIs

Sometimes you may be working with an old API that returns JSON in a less than ideal format or the URL or parameters required have changed.

If it's simply that you want attribute names like `SomeName` or `someName` to be more Ruby-style `some_name` then you can simply do that by setting `:rubify_names` when mapping an API call.

```ruby
class Article < Flexirest::Base
  base_url "http://www.example.com"

  get :all, "/all", rubify_names: true
end
```

In more complex cases you can define a descendent of `Flexirest::ProxyBase`, pass it to your model as the proxy and have it rework URLs/parameters on the way out and the response on the way back in (already converted to a Ruby hash/array). By default any non-proxied URLs are just passed through to the underlying connection layer. For example:

```ruby
class ArticleProxy < Flexirest::ProxyBase
  get "/all" do
    url "/all_people" # Equiv to url.gsub!("/all", "/all_people") if you wanted to keep params
    response = passthrough
    translate(response) do |body|
      body["first_name"] = body.delete("fname")
      body
    end
  end
end

class Article < Flexirest::Base
  proxy ArticleProxy
  base_url "http://www.example.com"

  get :all, "/all", fake:"{\"name\":\"Billy\"}"
  get :list, "/list", fake:"[{\"name\":\"Billy\"}, {\"name\":\"John\"}]"
end

Article.all.first_name == "Billy"
```

This example does two things:

1. It rewrites the incoming URL for any requests matching "_/all_" to "/all_people"
2. It uses the `translate` method to move the "fname" attribute from the response body to be called "first_name". The translate method must return the new object at the end (either the existing object alterered, or a new object to replace it with)

As the comment shows, you can use `url value` to set the request URL to a particular value, or you can call `gsub!` on the url to replace parts of it using more complicated regular expressions.

You can use the `get_params` or `post_params` methods within your proxy block to amend/create/delete items from those request parameters, like this:

```ruby
get "/list" do
  get_params["id"] = get_params.delete("identifier")
  passthrough
end
```

This example renames the get_parameter for the request from `identifier` to `id` (the same would have worked with post_params if it was a POST/PUT request). The `passthrough` method will take care of automatically recombining them in to the URL or encoding them in to the body as appropriate.

If you want to manually set the body for the API yourself you can use the `body` method

```ruby
put "/update" do
  body "{\"id\":#{post_params["id"]}}"
  passthrough
end
```

This example takes the `post_params["id"]` and converts the body from being a normal form-encoded body in to being a JSON body.

The proxy block expects one of three things to be the return value of the block.

1. The first options is that the call to `passthrough` is the last thing and it calls down to the connection layer and returns the actual response from the server in to the "API->Object" mapping layer ready for use in your application
2. The second option is to save the response from `passthrough` and use `translate` on it to alter the structure.
3. The third option is to use `render` if you want to completely fake an API and return the JSON yourself

To completely fake the API, you can do the following. Note, this is also achievable using the `fake` setting when mapping a method, however by doing it in a Proxy block means you can dynamically generate the JSON rather than just a hard coded string.

```ruby
put "/fake" do
  render "{\"id\":1234}"
end
```


-----

[< JSON API](json-api.md) | [Translating APIs >](translating-apis.md)
