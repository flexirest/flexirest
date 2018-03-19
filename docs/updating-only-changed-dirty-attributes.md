# *Flexirest:* Updating only changed/dirty attributes

The most common RESTful usage of the PATCH http-method is to only send fields that have changed. The default action for all calls is to send all known object attributes for POST/PUT/PATCH calls, but this can be altered by setting the `only_changed` option on your call declaration.

```ruby
class Person < Flexirest::Base
  get :all, '/people'
  patch :update, '/people/:id', :only_changed => true # only send attributes that are changed/dirty
end

person = Person.all.first
person.first_name = 'Billy'
person.update # performs a PATCH request, sending only the now changed 'first_name' attribute
```

This functionality is per-call, and there is some additional flexibility to control which attributes are sent and when.

```ruby
class Person < Flexirest::Base
  get :all, '/people'
  patch :update_1, '/people/:id', :only_changed => true # only send attributes that are changed/dirty (all known attributes on this object are subject to evaluation)
  patch :update_2, "/people/:id", :only_changed => [:first_name, :last_name, :dob] # only send these listed attributes, and only if they are changed/dirty
  patch :update_3, "/people/:id", :only_changed => {first_name: true, last_name: true, dob: false} # include the listed attributes marked 'true' only when changed; attributes marked 'false' are always included (changed or not, and if not present will be sent as nil); unspecified attributes are never sent
end
```

#### Additional Notes:

- The above examples specifically showed PATCH methods, but this is also available for POST and PUT methods for flexibility purposes (even though they break typical REST methodology).
- This logic is currently evaluated before Required Parameters, so it is possible to ensure that requirements are met by some clever usage.

  - This means that if a method is `:requires => [:active], :only_changed => {active: false}` then `active` will always have a value and would always pass the `:requires` directive (so you need to be very careful because the answer may end up being `nil` if you didn't specifically set it).


-----

[< Required parameters](required-parameters.md) | [HTTP/parse error handling >](httpparse-error-handling.md)
