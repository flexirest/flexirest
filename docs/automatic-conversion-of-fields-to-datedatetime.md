# *Flexirest:* Automatic conversion of fields to Date/DateTime

By default Flexirest will attempt to convert all fields to a `Date` or `DateTime` object if it's a string and the value matches certain regular expressions. However, on large responses this can be computationally expensive. You can disable this automatic conversion completely with:

```ruby
Flexirest::Base.disable_automatic_date_parsing = true
```

Additionally, you can specify when mapping the methods which fields should be parsed (so you can disable it in general, then apply it to particular known fields):

```ruby
class Person < Flexirest::Base
  get :all, '/people', parse_fields: [:created_at, :updated_at]
end
```

It is also possible to whitelist fields that should be parsed in your models, which is useful if you are instantiating these objects directly. The specified fields also apply automatically to request mapping.

```ruby
class Person < Flexirest::Base
  parse_date :updated_at, :created_at
end

# to disable all mapping
class Disabled < Flexirest::Base
  parse_date :none
end
```

This system respects `disable_automatic_date_parsing`, and will default to mapping everything - unless a `parse_date` whitelist is specified, or automatic parsing is globally disabled.

-----

[< Per-request parameter encoding](per-request-parameter-encoding.md) | [Raw requests >](raw-requests.md)
