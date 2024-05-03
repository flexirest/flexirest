# *Flexirest:* Caching

Expires and ETag based caching is enabled by default, but with a simple line in the application.rb/production.rb you can disable it:

```ruby
Flexirest::Base.perform_caching = false
```

or you can disable it per classes with:

```ruby
class Person < Flexirest::Base
  perform_caching false
end
```

or per request endpoint with:

```ruby
class Person < Flexirest::Base
    get :all, "/people", skip_caching: true
end
```

If Rails is defined, it will default to using Rails.cache as the cache store, if not, you'll need to configure one with a `ActiveSupport::Cache::Store` compatible object using:

```ruby
Flexirest::Base.cache_store = Redis::Store.new("redis://localhost:6379/0/cache")
```


-----

[< Combined example](combined-example.md) | [Using callbacks >](using-callbacks.md)
