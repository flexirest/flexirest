# *Flexirest:* XML Responses

Flexirest uses `Crack` to allow parsing of XML responses. For example, given an XML response of (with a content type of `application/xml` or `text/xml`):

```xml
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

  <title>Example Feed</title>
  <link href="http://example.org/"/>
  <updated>2003-12-13T18:30:02Z</updated>
  <author>
    <name>John Doe</name>
  </author>
  <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>

  <entry>
    <title>Atom-Powered Robots Run Amok</title>
    <link href="http://example.org/2003/12/13/atom03"/>
    <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
    <updated>2003-12-13T18:30:02Z</updated>
    <summary>Some text.</summary>
  </entry>

  <entry>
    <title>Something else cool happened</title>
    <link href="http://example.org/2015/08/11/andyjeffries"/>
    <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6b</id>
    <updated>2015-08-11T18:30:02Z</updated>
    <summary>Some other text.</summary>
  </entry>

</feed>
```

You can use:

```ruby
class Feed < Flexirest::Base
  base_url "http://www.example.com/v1/"
  get :atom, "/atom"
end

@atom = Feed.atom

puts @atom.feed.title
puts @atom.feed.link.href
@atom.feed.entry.each do |entry|
  puts "#{entry.title} -> #{entry.link.href}"
end
```

For testing purposes, if you are using a `fake` content response when defining your endpoint, you should also provide `fake_content_type: "application/xml"` so that the parser knows to use XML parsing.


-----

[< Debugging](debugging.md)
