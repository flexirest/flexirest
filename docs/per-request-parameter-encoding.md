# *Flexirest:* Per-request parameter encoding

When URL-encoding GET parameters, Rudy adds brackets(`[]`) by default to any parameters in an `Array`. For example, if you tried to pass these parameters:

```ruby
Person.all(param: [1, 2, 3])
```

Ruby would encode the URL as

```
?param[]=1&param[]=2&param[]=3
```

If you prefer flattened notation instead, pass a `params_encoder` option of `:flat` when mapping the call. So this call:

```ruby
class Person < Flexirest::Base
  get :all, '/people', params_encoder: :flat
end
```

would output the following URL:

```
?param=1&param=2&param=3
```


-----

[< Per-request timeouts](per-request-timeouts.md) | [Automatic conversion of fields to Date/DateTime >](automatic-conversion-of-fields-to-datedatetime.md)
