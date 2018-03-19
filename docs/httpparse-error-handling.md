# *Flexirest:* HTTP/parse error handling

Sometimes the backend server may respond with a non-200/304 header, in which case the code will raise an `Flexirest::HTTPClientException` for 4xx errors or an `Flexirest::HTTPServerException` for 5xx errors. These both have a `status` accessor and a `result` accessor (for getting access to the parsed body):

```ruby
begin
  Person.all
rescue Flexirest::HTTPClientException, Flexirest::HTTPServerException => e
  Rails.logger.error("API returned #{e.status} : #{e.result.message}")
end
```

If the response is unparsable (e.g. not in the desired content type), then it will raise an `Flexirest::ResponseParseException` which has a `status` accessor for the HTTP status code and a `body` accessor for the unparsed response body.

-----

[< Updating only changed/dirty attributes](updating-only-changed-dirty-attributes.md) | [Validation >](validation.md)
