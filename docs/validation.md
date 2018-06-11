# *Flexirest:* Validation

Flexirest comes with its own validation. It is very similar to the Rails' built in ActiveModel validations. For example:

```ruby
class Person < Flexirest::Base
  validates :first_name, presence: true #ensures that the value is present and not blank
  validates :last_name, existence: true #ensures that the value is non-nil only
  validates :password, length: {within:6..12}, message: "Invalid password length, must be 6-12 characters"
  validates :post_code, length: {minimum:6, maximum:8}
  validates :salary, numericality: true, minimum: 20_000, maximum: 50_000
  validates :age, numericality: { minumum: 18, maximum: 65 }
  validates :suffix, inclusion: { in: %w{Dr. Mr. Mrs. Ms.}}

  validates :first_name do |object, name, value|
    object._errors[name] << "must be over 4 chars long" if value.length <= 4
  end

  get :index, '/'
end
```


Note: the block based validation is responsible for adding errors to `object._errors[name]` (and this will automatically be ready for `<<` inserting into).

Validations are run when calling `valid?` or when calling any API on an instance (and then only if it is `valid?` will the API go on to be called).

`full_error_messages` returns an array of attributes with their associated error messages, i.e. `["age must be at least 18"]`. Custom messages can be specified by passing a `:message` option to `validates`. This differs slightly from ActiveRecord in that it's an option to `validates` itself, not a part of a final hash of other options. This is because the author doesn't like the ActiveRecord format (but will accept pull requests that make both syntaxes valid). To make this clearer, an example may help:

```ruby
# ActiveRecord
validates :name, presence: { message: "must be given please" }

# Flexirest
validates :name, :presence, message: "must be given please"
```

## Permitting nil values

The default behavior for `:length`, `:numericality` and `:inclusion` validators is to fail when a `nil` value is encountered. You can prevent `nil` attribute values from triggering validation errors for attributes that may permit `nil` by adding the `:allow_nil => true` option. Adding this option with a `true` value to `:length`, `:numericality` and `:inclusion` validators will permit `nil` values and not trigger errors. Some examples are:

```ruby
class Person < Flexirest::Base
  validates :first_name, presence: true
  validates :middle_name, length: { minimum: 2, maximum: 30 }, allow_nil: true
  validates :last_name, existence: true
  validates :nick_name, length: { minimum: 2, maximum: 30 }
  validates :alias, length: { minimum: 2, maximum: 30 }, allow_nil: false
  validates :password, length: { within: 6..12 }
  validates :post_code, length: { minimum: 6, maximum: 8 }
  validates :salary, numericality: true, minimum: 20_000, maximum: 50_000
  validates :age, numericality: { minimum: 18, maximum: 65 }
  validates :suffix, inclusion: { in: %w{Dr. Mr. Mrs. Ms.}}
  validates :golf_score, numericality: true, allow_nil: true
  validates :retirement_age, numericality: { minimum: 65 }, allow_nil: true
  validates :cars_owned, numericality: true
  validates :houses_owned, numericality: true, allow_nil: false
  validates :favorite_authors, inclusion: { in: ["George S. Klason", "Robert T. Kiyosaki", "Lee Child"] }, allow_nil: true
  validates :favorite_artists, inclusion: { in: ["Claude Monet", "Vincent Van Gogh", "Andy Warhol"] }
  validates :favorite_composers, inclusion: { in: ["Mozart", "Bach", "Pachelbel", "Beethoven"] }, allow_nil: false
end
```

In the example above, the following results would occur when calling `valid?` on an instance where all attributes have `nil` values:

- `:first_name` must be present
- `:last_name` must be not be nil
- `:nick_name` must be not be nil
- `:alias` must not be nil
- `:password` must not be nil
- `:post_code` must not be nil
- `:salary` must not be nil
- `:age` must not be nil
- `:suffix` must not be nil
- `:cars_owned` must not be nil
- `:houses_owned` must not be nil
- `:favorite_artists` must not be nil
- `:favorite_composers` must not be nil

The following attributes will pass validation since they explicitly `allow_nil`:

- `:middle_name`
- `:golf_score`
- `:retirement_age`
- `:favorite_authors`

## ActiveModel::Validations

This built-in validations have a bit different syntax than the ActiveModel validations and use a different codebase.

You can opt-out from the built-in validations and use the `ActiveModel` validations instead if you inherit from the `Flexirest::BaseWithoutValidation` class instead of the `Flexirest::Base`.

Here is the same example what you could see at the top but with `ActiveModel` validations:


```ruby
class Person < Flexirest::BaseWithoutValidation
  include ActiveModel::Validations

  validates :first_name, :last_name, presence: true # ensures that the value is present and not blank
  validates :password, length: { within: 6..12, message: "Invalid password length, must be 6-12 characters" }
  validates :post_code, length: { minimum: 6, maximum: 8 }
  validates :salary, numericality: { greater_than_or_equal_to: 20_000, less_than_or_equal_to: 50_000 }
  validates :age, numericality: { greater_than_or_equal_to: 18, less_than_or_equal_to: 65 }
  validates :suffix, inclusion: { in: %w{Dr. Mr. Mrs. Ms.} }

  validate do
    errors.add(:name, "must be over 4 chars long") if first_name.length <= 4
  end

  get :index, '/'
end
```


-----

[< HTTP/parse error handling](httpparse-error-handling.md) | [Filtering result lists >](filtering-result-lists.md)
