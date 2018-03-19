# *Flexirest:* Using callbacks

You can use callbacks to alter get/post parameters, the URL or set the post body (doing so overrides normal parameter insertion in to the body) before a request or to adjust the response after a request. This can either be a block or a named method (like ActionController's `before_callback`/`before_action` methods).

The callback is passed the name of the method (e.g. `:save`) and an object (a request object for `before_request` and a response object for `after_request`). The request object has four public attributes `post_params` (a Hash of the POST parameters), `get_params` (a Hash of the GET parameters), `headers` and `url` (a `String` containing the full URL without GET parameters appended).

```ruby
require 'secure_random'

class Person < Flexirest::Base
  before_request do |name, request|
    if request.post? || name == :save
      id = request.post_params.delete(:id)
      request.get_params[:id] = id
    end
  end

  before_request :replace_token_in_url

  before_request :add_authentication_details

  before_request :replace_body

  before_request :override_default_content_type

  private

  def replace_token_in_url(name, request)
    request.url.gsub!("#token", SecureRandom.hex)
  end

  def add_authentication_details(name, request)
    request.headers["X-Custom-Authentication-Token"] = ENV["AUTH_TOKEN"]
  end

  def replace_body(name, request)
    if name == :create
      request.body = request.post_params.to_json
    end
  end

  def override_default_content_type(name, request)
    if name == :save
      request.headers["Content-Type"] = "application/json"
    end
  end
end
```

If you need to, you can create a custom parent class with a `before_request` callback and all children will inherit this callback.

```ruby
class MyProject::Base < Flexirest::Base
  before_request do |name, request|
    request.get_params[:api_key] = "1234567890-1234567890"
  end
end

class Person < MyProject::Base
  # No need to declare a before_request for :api_key, already defined by the parent
end
```

After callbacks work in exactly the same way:

```ruby
class Person < Flexirest::Base
  get :all, "/people"

  after_request :fix_empty_content
  after_request :cache_all_people

  private

  def fix_empty_content(name, response)
    if response.status == 204 && response.body.blank?
      response.body = '{"empty": true}'
    end
  end

  def cache_all_people(name, response)
    if name == :all
      response.response_headers["Expires"] = 1.hour.from_now.iso8601
    end
  end
end
```

**Note:** since v1.3.21 the empty response trick above isn't necessary, empty responses for 204 are accepted normally (the method returns `true`), but this is here to show an example of an `after_request` callback adjusting the body. The `cache_all_people` example shows how to cache a response even if the server doesn't send the correct headers.

If you want to trap an error in an `after_request` callback and retry the request, this can be done - but retries will only happen once for each request (so we'd recommend checking all conditions in a single `after_request` and then retrying after fixing them all). You achieve this by returning `:retry` from the callback.

```ruby
class Person < Flexirest::Base
  get :all, "/people"

  after_request :fix_invalid_request

  private

  def fix_invalid_request(name, response)
    if response.status == 401
      # Do something to fix the state of caches/variables used in the 
      # before_request, etc
      return :retry
    end
  end
end
```


-----

[< Caching](caching.md) | [Lazy loading >](lazy-loading.md)
