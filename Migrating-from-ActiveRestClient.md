# Migrating from ActiveRestClient

While contracting at Which? Ltd I wrote a library in Ruby to access REST APIs in a very flexible, almost ActiveRecord style. This was agreed (after long discussions with the legal department) to be released as open source.

Unfortunately after leaving Which? the gem was used less and less as I believe they were re-architecting to not rely on backend servers built in Java anymore.

In October 2015 I decided that I didn't want this gem that I'd built to fall by the wayside, so I forked under the name Flexirest (which wasn't listed as a gem at RubyGems.org) and released it.

Since then I've continued to update the library with fixes and some minor new features (it's working really well and is pretty functionally complete, so there isn't much to add there at this point), but some people continue to post bugs/pull requests on the ActiveRestClient GitHub page.

So, if you've seen this link on https://github.com/whichdigital/active-rest-client/ the chances are I've sent you a link to it to show you the reasons why you should switch to Flexirest and how...

## How to change

The first step is to change the line in your Gemfile from:

```ruby
gem "active-rest-client"  
```

to read:

```ruby
gem 'flexirest'  
```

and then re-run `bundle install`.

The second step is to find and replace across your codebase all instances of `ActiveRestClient` with `Flexirest`.

The third and final step is to clear your Rails cache. The easiest way of doing this is to type `Rails.cache.clear` in a Rails console.

That's it, you've now switched over to Flexirest with a)lots of bug fixes, b)support for PATCH requests and c)someone actively continuing to support it!