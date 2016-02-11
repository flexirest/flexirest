# Changelog

## 1.2.19

Features:

- Allow procs in defaults to be able to use params (for Michael Mealling)

## 1.2.18

Features:

- Allow nil option in validators (thanks to Jurgen Jocubeit)
- Added array feature for returning simple scalar values (thanks to Jurgen Jocubeit)

## 1.2.17

Bugfixes:

- Corrected parsing of dates/datetimes coming in responses (thanks to Matthias Neumayr)

## 1.2.16

Feature:

- Replaces URL :keyed parameters for direct requests.

## 1.2.15

Feature:

- Fixing issue when moving from ActiveRestClient to Flexirest - cached responses have the old class in them, so come through as a String

## 1.2.14

Bugfixes:

- Patch was partially implemented in 2014, but never completed. It should be working now (thanks to Joel Low)

# Changelog

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
