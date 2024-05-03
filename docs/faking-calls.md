# *Flexirest:* Faking calls

There are times when an API hasn't been developed yet, so you want to fake the API call response. To do this, you can simply pass a `:fake` option when mapping the call containing the response.

```ruby
class Person < Flexirest::Base
  get :all, '/people', fake: [{first_name:"Johnny"}, {first_name:"Bob"}]
end
```

You may want to run a proc when faking data (to put information from the parameters in to the response or return different responses depending on the parameters). To do this just pass a proc to `:fake`:

```ruby
class Person < Flexirest::Base
  get :all, '/people', fake: ->(request) { {result: request.get_params[:id]} }
end
```

Alternatively, you can specify a symbol as the `fake` parameter, and Flexirest will call that method to get a string JSON as if it was the request body:

```ruby
class Person < Flexirest::Base
  get :all, '/people', fake: :get_data

  def get_data
    {result: true}.to_json
  end
end
```

-----

[< Parallel requests](parallel-requests.md) | [Per-request timeouts >](per-request-timeouts.md)
