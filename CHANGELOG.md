# Changelog

## 1.3.15

Feature:

- Allows setting of the ApiAuth `:digest` or `:override_http_method` if v2.0 or above of ApiAuth is installed (thanks to Alan Ruth for the request).

## 1.3.14

Feature:

- Plain Requests (both using the `plain: true` option to mapped methods and using `_plain_request`) return a `Flexirest::PlainResponse` which is string-like for all intents and purposes (it's comparable with strings using the body of the response) and also has `_status` and `_headers` methods (thanks to Rui Ribeiro for the request/inspiration).

## 1.3.13

Feature:

- The undocumented `plain: true` option to mapped methods was tested and documented.

## 1.3.12

Bugfix:

- The Travis build was breaking because Guard pulls in Listen, which only runs on Ruby 2.2 and above. So I removed Guard so the gem can be tested to work against older Ruby versions still.

## 1.3.11

Feature:

- Made the `Flexirest::*Exception#message` much nicer to help debugging applications, e.g. `Sending PUT to '/enable' returned a 500 with the body of - {"error":"John doesn't exist", "code":1234}`.

## 1.3.10

Feature:

- Added per-request params encoding so you can choose between `param[]=foo&param[]=bar` or `param=foo&param=bar` (thanks to bkubic for the PR).

## 1.3.9

Feature:

- Proxying now works for PATCH requests, along with the existing GET, POST, PUT and DELETE (thanks to Andrew Schaper for the PR).

## 1.3.8

Bugfix:

- Fixing crash when trying to parse a JSON response body for error codes and no translator present.

## 1.3.7

Bugfix:

- Removed some more warnings about using uninitialized variables (thanks to Joel Low for the heads-up).

## 1.3.6

Bugfix:

- Removed some warnings about using uninitialized variables (thanks to Joel Low for the heads-up).

## 1.3.5

Bugfix:

- Deeply nested has_many relationships weren't working (thanks to Lewis Buckley for the bug report, spec and fix).

## 1.3.4

Features:

- Allows assigning `STDOUT` to `Flexirest::Logger.logfile` which can be useful when debugging Flexirest or applications at the console (either `rails console` from a Rails app or `rake console` from within Flexirest's codebase) along with setting `verbose!` on the class.

## 1.3.3

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

## 1.0.9

Bugfixes

- Correctly handling invalid cache expiry times

## 1.0.8

Features:

- Added Api-Auth for authentication against APIs that use it
- Supporting array parameter types
- Relationships for 'has_one' can now be used
