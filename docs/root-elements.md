# *Flexirest:* Root elements

If your response comes back with a root node and you'd like to ignore it, you can define the mapping as:

```ruby
class Feed < Flexirest::Base
  post :list, "/feed", ignore_root: "feed"
end
```

This also works if you'd want to remove a tree of root nodes:

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

You can do it like this:

```ruby
class Feed < Flexirest::Base
  post :list, "/feed", wrap_root: "feed"
end

Feed.list(id: 1)
```


-----

[< Default parameters](default-parameters.md) | [Required parameters >](required-parameters.md)
