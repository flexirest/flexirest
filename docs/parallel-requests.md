# *Flexirest:* Parallel requests

Sometimes you know you will need to make a bunch of requests and you don't want to wait for one to finish to start the next. When using parallel requests there is the potential to finish many requests all at the same time taking only as long as the single longest request. To use parallel requests you will need to set Flexirest to use a Faraday adapter that supports parallel requests [(such as Typhoeus)](https://github.com/lostisland/faraday/wiki/Parallel-requests).

```ruby
# Set adapter to Typhoeus to use parallel requests
Flexirest::Base.adapter = :typhoeus
```

Now you just need to get ahold of the connection that is going to make the requests by specifying the same host that the models will be using. When inside the `in_parallel` block call request methods as usual and access the results after the `in_parallel` block ends.

```ruby
Flexirest::ConnectionManager.in_parallel('https://www.example.com') do
    @person = Person.find(1234)
    @employers = Employer.all

    puts @person #=> nil
    puts @employers #=> nil
end # The requests are all fired in parallel during this end statement

puts @person.name #=> "John"
puts @employers.size #=> 7
```


-----

[< Body types](body-types.md) | [Faking calls >](faking-calls.md)
