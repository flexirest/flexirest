# *Flexirest:* Faraday configuration

Flexirest uses Faraday to allow switching HTTP backends, the default is to just use Faraday's default. To change the used backend just set it in the class by setting `adapter` to a Faraday supported adapter symbol.

```ruby
Flexirest::Base.adapter = :net_http
# or ...
Flexirest::Base.adapter = :patron
```

In versions before 1.2.0 the adapter was hardcoded to `:patron`, so if you want to ensure it still uses Patron, you should set this setting.

If you want more control you can pass a **complete** configuration block ("complete" means that the block does not _override_ [the default configuration](https://github.com/flexirest/flexirest/blob/5b1953d89e26c02ca74f74464ccb7cd4c9439dcc/lib/flexirest/configuration.rb#L184-L201), but rather _replaces_ it).

For available configuration variables look into the [Faraday documentation](https://github.com/lostisland/faraday).

```ruby
Flexirest::Base.faraday_config do |faraday|
  faraday.adapter(:net_http)
  faraday.options.timeout       = 10
  faraday.ssl.verify            = false
  faraday.headers['User-Agent'] = "Flexirest/#{Flexirest::VERSION}"
end
```


-----

[< Ruby on Rails integration](ruby-on-rails-integration.md) | [Associations >](associations.md)
