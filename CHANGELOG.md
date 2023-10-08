# Changelog

## 1.12.0

Bugfix:

- Add compatibility with Ruby on Rails 7.1 (requires a method on the logger)

## 1.11.3

Bugfix:

- Forward all Flexirest::ResultIterator#index arguments to allow for code like `result.index { |i| i == "z" }` (thanks to Stevo-S for the PR)

## 1.11.2

Bugfix:

- When a model had multiple lazy loaders specified, they would all have their object class set to the first object class that was found when iterating over them. (thanks to Joshua Samberg for the PR)

## 1.11.1

Enhancement:

- Add automatic expiry of cached responses based on the Expires header if set (thanks to Romain Gisiger for the issue and PR)

## 1.11.0

Major change:

- Dropped support for Ruby 2.x. Ruby 2.7 will be EOL in 27 days, and anyone can use the previous version 1.10 if they need 2.x support for the last month.

Enhancement:

- Added caching lines to the quiet! feature (thanks to Romain Gisiger for the issue and PR)

## 1.10.12

Enhancement:

- Added a quiet! mode to silence logging (thanks to Mujtaba Saboor for the issue and PR)

## 1.10.11

Bugfix:

- HTTPClientException's instance body was return nil instead of the response. (thanks to @pinifloyd for the issue and PR)

## 1.10.10

Bugfix:

- Specifically requiring a 1.x Faraday. They changed the engine inclusion in 2.x and it's not necessary for Flexirest to need that. If anyone does need it, feel free to raise a PR.

## 1.10.9

Bugfix:

- Correctly handle a 204 response to not wipe an instance's attributes (thanks to @couchbelag for the issue)
- Add an option to handle a 200 response with an empty body to not wipe an instance's attributes (thanks to @couchbelag for the issue)
- Fixed a couple of typos in error messages (thanks to Sampat Badhe/@sampatbadhe for the PR)

## 1.10.8

Bugfix:

- Flexirest didn't set DELETE params in the URL if send_request_body was false

## 1.10.7

Bugfix:

- Flexirest didn't find the elements if the specified root wasn't found, e.g. in error conditions (thanks to Jolyon Pawlyn/@jpawlyn for the PR)

## 1.10.6

Bugfix:

- Flexirest was erroring if Rails.logger was defined but was nil (thanks to Alex Oxte for the PR)

## 1.10.5

Enhancement:

- Allow skipping of caching for single endpoints

## 1.10.4

Enhancement:

- Implement support for in-header Basic Auth (thanks to François Ferrandis for the PR)

## 1.10.3

Enhancement:

- Ignore/wrap root functionality available for all routes, rather than just route specifically (thanks to Sampat Badhe for the PR)

## 1.10.2

Bugfix:

- JSON-API calls do not include linked resources when no other parameter is passed (thanks to Stevo-S for the bug report and François Ferrandis for the PR)

## 1.10.1

Enhancement:

- Nested objects now report their dirty/changed status up to the parent (thanks to Matthias Hähnel for the bug report)

## 1.10.0

Enhancement:

- Add specific exceptions for the most common 5xx server-side errors

## 1.9.18

Security:

- Upgrade rest-client development dependency to a CVE-fixed version.

## 1.9.17

Feature:

- Methods can be specified as a symbol for generating fake data (thanks to Niall Duggan for the feature request).

## 1.9.16

Bugfix:

- Cached responses were always returning as `dirty?`/`changed?` (thanks to AKRathore for the bug report).

## 1.9.15

Bugfix:

- Fix not marking unchanged attributes as dirty (thanks to Khairi Adnan for the bug report).

## 1.9.14

Bugfix:

- Remove deprecation warning for `URI.escape` on Ruby 2.7.x.

## 1.9.13

Change:

- Unified the response body to be `body` for all exceptions instead of sometimes being `body` and sometimes being `raw_response`, although both are available as aliases where they were defined before (thanks to Romain Gisiger for the PR).
- Adjust parsing of attributes to be done in a more unified way and lighten the CPU load (thanks to Romain Gisiger for the PR)

## 1.9.12

Bugfix:

- Prevent crash on JSONAPI invalid error response (thanks to François Ferrandis for the PR).

## 1.9.11

Bugfix:

- Prevent crash when JSONAPI response["data"] is an empty array (thanks to François Ferrandis for the PR).

## 1.9.10

Bugfix:

- Correctly handle errors in JSONAPI calls (thanks to François Ferrandis for the PR).

Important: Note, because a gem was accidentally pushed as version 1.9.10 instead of 1.9.0, there will be no 1.9.0 to 1.9.9, to reduce the risk of someone having updated to the accidental high version increase. Sorry about that

## 1.8.9

Feature:

- Adds proc support to api_auth credentials (thanks to David Underwood for the PR).

## 1.8.8

Fix:

- Use custom type and name for JSON-API fields (thanks to François Ferrandis for the PR).
- Fix Faraday error classes to match current ones in Faraday (thanks to François Ferrandis for the PR).

## 1.8.7

Fix:

- URL parameters should be automatically required or you end up requesting incorrect URLs (thanks to Marko Kind, @m-kind for the issue).

## 1.8.6

Fix:

- Correct HTTP status code for too many requests (thanks to Tomohiko Mimura, @mito5525 for spotting this).

## 1.8.5

Fix:

- Array and Hash parameters should not have their fieldname CGI escaped, Rails doesn't like it and the RFC doesn't require it

## 1.8.4

Fix:

- Array and Hash parameters should be accepted in `:form_multipart`

## 1.8.3

Fix:

- Missed dependency that should have been specified.

## 1.8.2

Features:

- Allowed use of `:form_multipart` as a `request_body_type` to allow uploading files to an API.

## 1.8.1

Features:

- Added a specific `Flexirest::HTTPTooManyRequestsClientException` for 429 errors, to enable easier trapping

## 1.8.0

Features:

- For the weird situations where the remote API expects some weird formatted input, you can now specify a `request_body_type` of plain and pass in to the call `body` (and optionally `content_type`) to pass it untouched to the API. The [docs](docs/body-types.md) have been updated.

## 1.7.9

Features:

- The `ignore_root` method now can ignore a tree of labels, rather than just one top level (thanks to gkosmr for the issue and pull request)

## 1.7.8

Fix:

- plain requests to URLs that are just the domain e.g. "<https://www.example.com>" should also work (i.e. without any trailing path, even a '/')

## 1.7.7

Change:

- Set the default charset to UTF-8 for form encoded request bodies, the same as it already was for JSON encoded request bodies.

## 1.7.6

Feature:

- Changed `Flexirest::HTTPException#message` and `#to_s` for a better description of the error than just the class name.

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
