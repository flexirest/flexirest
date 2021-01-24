# *Flexirest:* Root elements

If your response comes back with a root node and you'd like to ignore it, you can define the mapping as:

```ruby
Flexirest::Base.ignore_root = "data"
```

Any `ignore_root` setting in specific class overrides this declared default.

```ruby
class Feed < Flexirest::Base
  ignore_root: "feed"

  post :list, "/feed"
end
```

And any `ignore_root` setting in specific request overrides the both default and class specific setting.


```ruby
class Feed < Flexirest::Base
  ignore_root: 'feed'

  post :list, "/feed", ignore_root: "result"
end
```

You can also assign an array to `ignore_root` if you'd want to remove a tree of root nodes.

```ruby
class Feed < Flexirest::Base
  post :list, "/feed", ignore_root: ["feed", "items"]
end
```

Alternatively if you want to wrap your JSON request body in a root element, e.g.:

```json
{
  "feed": {
    "id": 1
  }
}
```

You can do it using `wrap_root`:

```ruby
Flexirest::Base.wrap_root = "data"
```

Any `wrap_root` setting in specific class overrides this declared default.

```ruby
class Feed < Flexirest::Base
  wrap_root: "feed"

  post :list, "/feed"
end
```

And any `wrap_root` setting in specific request overrides the both default and class specific setting.


```ruby
class Feed < Flexirest::Base
  wrap_root: 'feed'

  post :list, "/feed", wrap_root: "data"
end
```

-----

[< Default parameters](default-parameters.md) | [Required parameters >](required-parameters.md)
