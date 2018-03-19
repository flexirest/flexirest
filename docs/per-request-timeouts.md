# *Flexirest:* Per-request timeouts

There are times when an API is generally quick, but one call is very intensive. You don't want to set a global timeout in the Faraday configuration block, you just want to increase the timeout for this single call. To do this, you can simply pass a `timeout` option when mapping the call containing the response (in seconds).

```ruby
class Person < Flexirest::Base
  get :all, '/people', timeout: 5
end
```

-----

[< Faking calls](faking-calls.md) | [Per-request parameter encoding >](per-request-parameter-encoding.md)
