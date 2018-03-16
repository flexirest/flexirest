### Expected behaviour

When I use the (something) method, I get this exception xyz...

### Desired behaviour

It should call the remote server correctly and not raise an exception

### How to reproduce

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
