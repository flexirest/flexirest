# Flexirest

> Access your REST APIs in a flexible way.
>
> Write your API classes in an ActiveRecord-style; like ActiveResource but Flexirest works where the resource naming doesn't follow Rails conventions, it has built-in caching and is much more flexible.

[![Build](https://github.com/flexirest/flexirest/actions/workflows/build.yml/badge.svg)](https://github.com/flexirest/flexirest/actions/workflows/build.yml)
[![Coverage Status](https://coveralls.io/repos/github/flexirest/flexirest/badge.svg?branch=master)](https://coveralls.io/github/flexirest/flexirest?branch=master)
[![Code Climate](https://codeclimate.com/github/flexirest/flexirest.png)](https://codeclimate.com/github/flexirest/flexirest)
[![Gem Version](https://badge.fury.io/rb/flexirest.png)](http://badge.fury.io/rb/flexirest)
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/flexirest/flexirest.svg)](http://isitmaintained.com/project/flexirest/flexirest "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/flexirest/flexirest.svg)](http://isitmaintained.com/project/flexirest/flexirest "Percentage of issues still open")

## Background

If you are a previous user of [ActiveRestClient](https://github.com/whichdigital/active-rest-client), there's some more information on [why I created this fork and how to upgrade](docs/migrating-from-activerestclient.md) - but long story short, I wrote most of the code as a previous gem for a client, they agreed to open-source it, then it was abandoned and I relaunched it and now support it myself (and the owners of ActiveRestClient have acknowledged their gem is deprecated in favour of Flexirest).

## Quickstart

Assuming you're using [Bundler](http://bundler.io), to use Flexirest add this line to your application's Gemfile:

```ruby
gem 'flexirest'
```

And then execute:

```
$ bundle
```

To use it, let's create a new model class:

```ruby
# app/models/person.rb
class Person < Flexirest::Base
  base_url "https://www.example.com/api/v1"

  get :all, "/people"
  get :find, "/people/:id"
  put :save, "/people/:id"
  post :create, "/people"
  delete :remove, "/people/:id"
end
```

You can then use your new class like this:

```ruby
# Create a new person
@person = Person.create(
  first_name: "John",
  last_name: "Smith"
)

# Find a person (not needed after creating)
id = @person.id
@person = Person.find(id)

# Update a person
@person.last_name = "Jones"
@person.save

# Get all people
@people = Person.all
@people.each do |person|
  puts "Hi " + person.first_name
end
```

## Reading further

I've written a TON of documentation on how to use Flexirest and a LITTLE bit on how it works internally. For more information see the following pages:

- [Basic Usage](docs/basic-usage.md)
- [Ruby on Rails integration](docs/ruby-on-rails-integration.md)
- [Faraday configuration](docs/faraday-configuration.md)
- [Associations](docs/associations.md)
- [Combined example](docs/combined-example.md)
- [Caching](docs/caching.md)
- [Using callbacks](docs/using-callbacks.md)
- [Lazy loading](docs/lazy-loading.md)
- [Authentication](docs/authentication.md)
- [Body types](docs/body-types.md)
- [Empty body handling](docs/empty-body-handling.md)
- [Parallel requests](docs/parallel-requests.md)
- [Faking calls](docs/faking-calls.md)
- [Per-request timeouts](docs/per-request-timeouts.md)
- [Per-request parameter encoding](docs/per-request-parameter-encoding.md)
- [Automatic conversion of fields to Date/DateTime](docs/automatic-conversion-of-fields-to-datedatetime.md)
- [Raw requests](docs/raw-requests.md)
- [Plain requests](docs/plain-requests.md)
- [JSON API](docs/json-api.md)
- [Proxying APIs](docs/proxying-apis.md)
- [Translating APIs - DEPRECATED](docs/translating-apis.md)
- [Default parameters](docs/default-parameters.md)
- [Root elements](docs/root-elements.md)
- [Required parameters](docs/required-parameters.md)
- [Updating only changed/dirty attributes](docs/updating-only-changed-dirty-attributes.md)
- [HTTP/parse error handling](docs/httpparse-error-handling.md)
- [Validation](docs/validation.md)
- [Filtering result lists](docs/filtering-result-lists.md)
- [Logging](docs/logging.md)
- [XML responses](docs/xml-responses.md)


## Licence

Code originally copyright© 2013 Which? Ltd, released with an MIT License and now this fork is released under the same licence by Andy Jeffries.

**MIT License**

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/flexirest/flexirest/issues) to report any bugs or file feature requests.

If you want to generate a reproducible bug report, here are some steps to follow in your bug report:

1. Clone the Flexirest repo (`git clone https://github.com/flexirest/flexirest.git`)
2. Change to the flexirest folder (`cd flexirest`)
3. Install any dependencies (`bundle install`)
4. Run an interactive console (`rake c`)
5. Paste the following:

```ruby
class MyObject < Flexirest::Base
  base_url "https://requestb.in"
  post :create, "/{CREATE_A_PASTEBIN_ID}"
end

my_object = MyObject.new(params: "something")
my_object.create
# => something is output to the terminal
```

### Working on the codebase

The general steps are the same as for almost all codebases on GitHub:

1. Fork it and clone your fork
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request on GitHub.com

We have a guide written about [Flexirest Internals](docs/internals.md) if you want to know how it all hangs together. We also have lots of RSpec specifications, tested with Travis CI.
