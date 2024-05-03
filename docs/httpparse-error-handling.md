# *Flexirest:* HTTP/parse error handling

## HTTP Errors

Sometimes the backend server may respond with a non-2xx/3xx header, in which case the code will raise an `Flexirest::HTTPClientException` for 4xx errors or an `Flexirest::HTTPServerException` for 5xx errors. 

These both have a `status` accessor, a `result` accessor (for getting access to the parsed body) and a `body` accessor (for getting access to the original unparsed body). However, you can make use of the `message` method (or the `to_s` method) that will build a nice error message for you (containing the URL and the HTTP method used for the request as well as the HTTP status code and the original body of the response).

```ruby
begin
  Person.all
rescue Flexirest::HTTPClientException, Flexirest::HTTPServerException => e
  # Display the HTTP status and parsed body
  puts "Backend returned HTTP #{e.status} with following parsed body: #{e.result}"
  
  # Display the unparsed body
  puts "Original body is: #{e.body}"
  
  # Using the message method, same than calling the to_s method
  puts e.message
end
```

## Parse Error

If the original response is unparsable (e.g. not in the desired content type), then it will raise an `Flexirest::ResponseParseException` which has a `status` accessor for the HTTP status code and a `body` accessor for the unparsed response body.

-----

[< Updating only changed/dirty attributes](updating-only-changed-dirty-attributes.md) | [Validation >](validation.md)
