# *Flexirest:* Translating APIS (DEPRECATED)

**IMPORTANT: This functionality has been deprecated in favour of the [Proxying APIs](proxying-apis.md) functionality. You should aim to remove this from your code as soon as possible.**

Sometimes you may be working with an API that returns JSON in a less than ideal format. In this case you can define a barebones class and pass it to your model. The Translator class must have class methods that are passed the JSON object and should return an object in the correct format. It doesn't need to have a method unless it's going to translate that mapping though (so in the example below there's no list method). For example:

```ruby
class ArticleTranslator
  def self.all(object)
    ret = {}
    ret["first_name"] = object["name"]
    ret
  end
end

class Article < Flexirest::Base
  translator ArticleTranslator
  base_url "http://www.example.com"

  get :all, "/all", fake:"{\"name\":\"Billy\"}"
  get :list, "/list", fake:"[{\"name\":\"Billy\"}, {\"name\":\"John\"}]"
end

Article.all.first_name == "Billy"
```



-----

[< Proxying APIs](proxying-apis.md) | [Default parameters >](default-parameters.md)
