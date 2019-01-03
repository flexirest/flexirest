# Changelog

## 1.7.5

Feature:

- Implemented `Flexirest::ResultIterator#join` for closer to native handling of ActiveModel::Errors in Rails applications.

## 1.7.4

Feature:

- Returning `:retry` or now raising `Flexirest::CallbackRetryRequestException` from a callback will retry the current request.

## 1.7.3

Bugfix:

- Form encoded requests should also honour `wrap_root` (thanks to noctivityinc for the issue report)

Feature:

- Returning `false` from a callback will halt the callback chain and cancel the request (thanks to noctivityinc for the feature request)

## 1.7.2

Bugfix:

- JSON responses containing `null` crashed Flexirest, now they return a valid but empty object (thanks to Thomas Steinhausen for the PR)

## 1.7.1

Bugfix:

- Fixed fetching nested associations from the compound document when using JsonAPI standard requests (thanks to Mike Voets for the PR)

## 1.7.0

Feature:

- Allows using a Flexirest instance as a hash key (thanks to René from Crete Media Design for the PR)

## 1.6.9

Feature:

- Empty response bodies with an unparseable content-type are forced to be JSON with an empty JSON body

## 1.6.8

Feature:

- A refactoring to allow users to chose to use ActiveModel validation instead of the custom ActiveModel-like validation built in to Flexirest. In a future release this will become the default. (thanks to KARASZI István for the pull request)

## 1.6.7

Bugfix:

- Returning the string value for a field that looks like a Date/DateTime instead of raising an error when the value can't be parsed (thanks to Give Corps for the pull request)

## 1.6.6

Feature:

- Username and Password can now take a block/proc for dynamically retrieving the username and password, and will pass in the object if called in a current object context (thanks to Sam Starling for suggesting this lack of functionality)

## 1.6.5

Bugfix:

- Plain requests were having the URL output to the log twice (thanks to Dan W for reporting this)

## 1.6.4

Feature:

- Added the ability to automatically change attributes returned from an API like `SomeName` or `someName` to Ruby-style `some_name` by setting `:rubify_names` when mapping an API call.

## 1.6.3

Bugfix:

- Allowing instantiating a class if mapped request method is called for "JSON-API" functionality (thanks to Mike Voets for this PR).

## 1.6.1

Feature:

- Added `where` filtering to result iterators (thanks to Jeljer te Wies for the feature).

## 1.6.0

Feature:

- APIs that expect request bodies to have a wrapping element can now have this specified at mapping time.

## 1.5.9

Bugfix:

- Added missing `get?`, `post?`, `put?` and `delete?` methods to request as they were used in the documentation.

## 1.5.8

Feature:

- Allow retrying after a failure in an `after_request` callback

## 1.5.7

Bugfix:

- Exceptions don't display a message if no method was set (internal exception?)

## 1.5.6

Feature:

- Allow deleting of default headers in `before_request` callbacks

## 1.5.5

Bugfix:

- Fixing already encoded bodies in plain requests

## 1.5.4

Feature:

- Changing `_request` to accept options, including `:headers`, rather than headers directly

## 1.5.3

Feature:

- Allow passing custom headers as an option to raw requests.

## 1.5.2

Bugfix:

- Some APIs return an empty response body even on 200s, so any valid status with an empty body should be handled nicely

## 1.5.1

Bugfix:

- PUT/POST/PATCH methods called on an instantiated object should merge the objects attributes with specified params.

## 1.5.0

Bugfix:

- GET requests with the same URL as PUT requests shouldn't use the etag cached version.

## 1.4.8/1.4.9

Bugfix:

- Responses without content (202, 204) will return an empty object.

## 1.4.7

Bugfix:

- Responses without content (202, 204) will still make the headers available in `_headers`.

## 1.4.6

Feature:

- You can define how to handle the body of `delete` requests now with the mapping option `send_delete_body`.

## 1.4.5

Bugfix:

- DELETE requests shouldn't send a request body, the body semantics are undefined.

## 1.4.4

Feature:

- Handling 202s without any content the same as a 204.

## 1.4.3

Feature:

- Added more client exceptions to allow fine grained exception trapping

## 1.4.2

Bugfix:

- Breakage in path parameters where the value isn't specified

## 1.4.1

Bugfix:

- Pluses in URL params are now escaped to %2B (thanks to jan-vitek for the bug report and pull request)

## 1.4.0

Feature:

- New JSON API support - thanks to Mike Voets for all his hard work!

## 1.3.35

Bugfix:

- Slashes in URL params are now escaped to %2F (thanks to davidtolsma for the bug report)

## 1.3.34

Feature:

- Added ActiveRecord/Mongoid style dirty/changed tracking methods (thanks to eshork for the PR)

Bugfix:

- Now can disable caching on subclasses after being enabled on a parent (thanks to yujideveloper for the PR)

## 1.3.33

Feature:

- Allowed specifying custom message for validation failures

## 1.3.32

Bugfix:

- Rolled back 1.3.31 - was an error in client code

## 1.3.31

Bugfix:

- Working with later versions of Faraday where the response seems to have lost response_headers

## 1.3.30

Bugfix:

- Restoring cached Flexirest::ResultIterators created via a Proxy wasn't restoring correctly

## 1.3.29

Bugfix:

- Setting `perform_caching` on `Flexirest::Base` was being ignored

## 1.3.28

Feature:

- Implemented delete_if on ResultIterator

## 1.3.27

Bugfix:

- HTTP GET requests shouldn't send any body, JSON-encoded or otherwise

## 1.3.26

Bugfix:

- Parameters sent within the URL (e.g. /foo/:bar) should be URI escaped or Flexirest raises an error about unparseable URLs

## 1.3.25

Feature:

- Improvements in performance due to date parsing (thanks to guanglunw for the PR)

## 1.3.24

Bugfix:

- Calling class methods on an instance where the instance is cacheable should work (thanks to johnmckinght for the bug report)

## 1.3.23

Bugfix:

- Should not parse multiline strings as `DateTime` when using the automatica parsing (thanks to execjosh for the PR)

## 1.3.22

Bugfix:

- Broke a test in v1.3.21 (according to Travis) which was passing locally, updated all my gems and then it broke locally, so reverted the test.

## 1.3.21

Feature:

- Now any requests returning a 204 with an empty (nil or blank) body return true instead of raising a ParseException

## 1.3.20

Bugfix:

- Fixed `has_one` association raising an error if there is no associated object (it should just return `nil`) (thanks to Azat Galikhanov for the PR)

## 1.3.19

Feature:

- Added Headers in to Flexirest::ResponseParseException to aid debugging of why it doesn't work against custom APIs.

## 1.3.18

Feature:

- Simplistic load balancing of API servers by supplying an array of URLs to `base_url`. It then pulls a random one out for each request.

## 1.3.17

Bugfix:

- Authentication credentials weren't being passed through proxied classes (thanks to Lukasz Modlinski for the contribution).

## 1.3.16

Feature:

- Allows disabling of the automatic date parsing with the `Flexirest::Base.disable_automatic_date_parsing` setting and/or specifying it per mapped method with the `:parse_fields` option (thanks to Michael Mealling for the request).

## 1.3.15

Feature:

- Allows setting of the ApiAuth `:digest` or `:override_http_method` if v2.0 or above of ApiAuth is installed (thanks to Alan Ruth for the request).

## 1.3.14

Feature:

- Plain Requests (both using the `plain: true` option to mapped methods and using `_plain_request`) return a `Flexirest::PlainResponse` which is string-like for all intents and purposes (it's comparable with strings using the body of the response) and also has `_status` and `_headers` methods (thanks to Rui Ribeiro for the request/inspiration).

## 1.3.13

Feature:

- The undocumented `plain: true` option to mapped methods was tested and documented.

## 1.3.12

Bugfix:

- The Travis build was breaking because Guard pulls in Listen, which only runs on Ruby 2.2 and above. So I removed Guard so the gem can be tested to work against older Ruby versions still.

## 1.3.11

Feature:

- Made the `Flexirest::*Exception#message` much nicer to help debugging applications, e.g. `Sending PUT to '/enable' returned a 500 with the body of - {"error":"John doesn't exist", "code":1234}`.

## 1.3.10

Feature:

- Added per-request params encoding so you can choose between `param[]=foo&param[]=bar` or `param=foo&param=bar` (thanks to bkubic for the PR).

## 1.3.9

Feature:

- Proxying now works for PATCH requests, along with the existing GET, POST, PUT and DELETE (thanks to Andrew Schaper for the PR).

## 1.3.8

Bugfix:

- Fixing crash when trying to parse a JSON response body for error codes and no translator present.

## 1.3.7

Bugfix:

- Removed some more warnings about using uninitialized variables (thanks to Joel Low for the heads-up).

## 1.3.6

Bugfix:

- Removed some warnings about using uninitialized variables (thanks to Joel Low for the heads-up).

## 1.3.5

Bugfix:

- Deeply nested has_many relationships weren't working (thanks to Lewis Buckley for the bug report, spec and fix).

## 1.3.4

Features:

- Allows assigning `STDOUT` to `Flexirest::Logger.logfile` which can be useful when debugging Flexirest or applications at the console (either `rails console` from a Rails app or `rake console` from within Flexirest's codebase) along with setting `verbose!` on the class.

## 1.3.3

Features:

- New Ruby on Rails integration guide (thanks to Matthias Neumayr)
- New `ignore_root` method to ignore JSON or XML root nodes, deprecated `ignore_xml_root` (thanks to dsarhadian for the request)

## 1.3.2

Features:

- Allow setting the body for a delete request - whether this is within HTTP spec is dubious, but a few APIs require it (thanks to Jeffrey Gu)

## 1.3.1

Features:

- You can now use `has_many`/`has_one` on the class live, more like ActiveRecord

## 1.3.0

Features:

- Allow a custom name to be set to be used in logging (thanks to Lewis Buckley)

## 1.2.19

Features:

- Allow procs in defaults to be able to use params (for Michael Mealling)

## 1.2.18

Features:

- Allow `nil` option in validators (thanks to Jurgen Jocubeit)
- Added array feature for returning simple scalar values (thanks to Jurgen Jocubeit)

## 1.2.17

Bugfixes:

- Corrected parsing of dates/datetimes coming in responses (thanks to Matthias Neumayr)

## 1.2.16

Feature:

- Replaces URL `:keyed` parameters for direct requests.

## 1.2.15

Feature:

- Fixing issue when moving from ActiveRestClient to Flexirest - cached responses have the old class in them, so come through as a String

## 1.2.14

Bugfixes:

- Patch was partially implemented in 2014, but never completed. It should be working now (thanks to Joel Low)

## 1.2.13

Bugfixes:

- Putting README.md back the way it was regarding ApiAuth (thanks to Kevin Glowacz)

## 1.2.12

Bugfixes:

- Correcting README.md to make ApiAuth usage clearer (thanks to Jeffrey Gu)

## 1.2.11

Bugfixes:

- Fixes the usage of :timeout on a per-request basis

## 1.2.10

Bugfixes:

- Changes the date regexes to not misinterpret strings of 8 digits to be dates (thanks Tom Hoen)

## 1.2.9

Bugfixes:

- Fixing messages used during validation of maximum numericality (thanks Tom Hoen)

## 1.2.8

Bugfixes:

- There was a strange problem with Flexirest defining methods on `Class` rather than on the specific class (which only presents itself when another class in the application is making use of `method_missing`).

## 1.2.7

Features:

- Adds a per request `timeout` option, for individually slow calls

## 1.2.5/1.2.6

Bugfixes:

- Fixes case when `Rails` exists but doesn't declare a `.cache` method

## 1.2.4 / 1.2.3

Bugfixes:

- Allows setting of `base_url`, `username`, `password` and `request_body_type` in a project-specific base class, then using that default in subclasses.
- Strings of four digits in the response are no longer treated as (invalid) dates (thanks Tom Hoen)
- 1.2.3 was pushed without a successful Travis build

## 1.2.2

Features:

- Adds `existence`, `numericality`, `presence` and `inclusion` validations (thanks Tom Hoen)
- Adds `full_error_messages` method (thanks Tom Hoen)
- Adds `requires` options to the method mapping

## 1.2.1

**Forked Which's ActiveRestClient to be Flexirest**

## 1.2.0

Features:

- Allows for beta-support for XML APIs as well as JSON ones.

Bugfixes:

- In order to allow JRuby to work with Flexirest, the hard-coded dependency on Patron has been removed.

## 1.1.10 - 1.1.12

Features:

- Parallel requests can now be made

Bugfixes

- Some work around Faraday's weird method naming
- Start of XML support
- URL encoding username and password

## 1.0.9

Bugfixes

- Correctly handling invalid cache expiry times

## 1.0.8

Features:

- Added Api-Auth for authentication against APIs that use it
- Supporting array parameter types
- Relationships for 'has_one' can now be used
