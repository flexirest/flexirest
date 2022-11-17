# *Flexirest:* Logging

## Verbose

You can turn on verbose logging to see what is sent to the API server and what is returned in one of these two ways:

```ruby
class Article < Flexirest::Base
  verbose true
end

class Person < Flexirest::Base
  verbose!
end
```

By default verbose logging isn't enabled, so it's up to the developer to enable it (and remember to disable it afterwards). It does use debug level logging, so it shouldn't fill up a correctly configured production server anyway.

If you prefer to record the output of an API call in a more automated fashion you can use a callback called `record_response` like this:

```ruby
class Article < Flexirest::Base
  record_response do |url, response|
    File.open(url.parameterize, "w") do |f|
      f << response.body
    end
  end
end
```

## Quiet

By the same token, if you want to silence all log output from Flexirest, you can use quiet:

```ruby
class Article < Flexirest::Base
  quiet true
end

class Person < Flexirest::Base
  quiet!
end
```

-----

[< Filtering result lists](filtering-result-lists.md) | [XML responses >](xml-responses.md)
