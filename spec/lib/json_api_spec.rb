require 'spec_helper'

class JsonAPIAssociationExampleTag < Flexirest::Base; end
class JsonAPIAssociationExampleAuthor < Flexirest::Base; end

class JsonAPIExampleArticle < Flexirest::Base
  has_many :tags, JsonAPIAssociationExampleTag
  has_one :author, JsonAPIAssociationExampleAuthor

  faker1 = {
    data: { id: 1, type: "article", attributes: { item: "item one" }, relationships: { "tags": { data: [ { id: 1, type: "tag" }, { id: 2, type: "tag" } ] } } },
    included: [ { id: 1, type: "tag", attributes: { item: "item two" } }, { id: 2, type: "tag", attributes: { item: "item three" } } ]
  }
  faker2 = {
    data: [
      { id: 1, type: "article", attributes: { item: "item one" }, relationships: { "tags": { data: [ { id: 1, type: "tag" }, { id: 2, type: "tag" } ] } } },
      { id: 2, type: "article", attributes: { item: "item four" }, relationships: { "tags": { data: [ { id: 2, type: "tag" } ] } } }
    ],
    included: [ { id: 1, type: "tag", attributes: { item: "item two" } }, { id: 2, type: "tag", attributes: { item: "item three" } } ]
  }
  faker3 = {
    data: { id: 1, type: "article", attributes: { item: "item one" }, relationships: { "author": { data: { id: 1, type: "author" } } } },
    included: [ { id: 1, type: "author", attributes: { item: "item two" } } ]
  }

  get :find, "/articles", fake: faker1.to_json, fake_content_type: "application/vnd.api+json"
  get :find_all, "/articles", fake: faker2.to_json, fake_content_type: "application/vnd.api+json"
  get :find_single_author, "/articles", fake: faker3.to_json, fake_content_type: "application/vnd.api+json"
end

class JsonAPILazyExampleAuthor < Flexirest::Base
  base_url "http://www.example.com"

  faker = { data: { id: 1, type: "author", attributes: { item: "item two" } } }

  get :find, "/articles/1/author", fake: faker.to_json, fake_content_type: "application/vnd.api+json"
end

class JsonAPILazyLoadingExample < Flexirest::Base
  base_url "http://www.example.com"
  has_one :author, JsonAPILazyExampleAuthor

  faker = {
    data: { id: 1, type: "article", attributes: { item: "item one" }, relationships: { "author": { links: { self: "http://www.example.com/articles/1/relationships/author", related: "http://www.example.com/articles/1/author" } } } }
  }

  get :find, "/articles", lazy: { author: JsonAPILazyExampleAuthor }, fake: faker.to_json, fake_content_type: "application/vnd.api+json"
end

module JsonAPIExample
  class Author < Flexirest::Base; end
  class Tag < Flexirest::Base; end

  class Article < Flexirest::Base
    base_url "http://www.example.com"
    request_body_type :json_api
    has_one :author, Author
    has_many :tags, Tag

    faker = {
      data: { id: 1, type: "article", attributes: { item: "item one" } }
    }

    get :find, "/articles/:id", fake: faker.to_json, fake_content_type: "application/vnd.api+json"
    post :create, "/articles"
    patch :update, "/articles/:id"
    delete :delete, "/articles/:id"
  end

  class ArticleAlias < Flexirest::Base
    alias_type :article
    base_url "http://www.example.com"
    request_body_type :json_api
    has_one :author, Author
    has_many :tags, Tag

    faker = {
      data: { id: 1, type: "article", attributes: { item: "item one" } }
    }

    get :find, "/articles/:id", fake: faker.to_json, fake_content_type: "application/vnd.api+json"
    patch :update, "/articles/:id"
  end
end

describe "JSON API" do
  let(:subject) { JsonAPIExampleArticle.new }
  let(:lazy) { JsonAPILazyLoadingExample.new }

  context "responses" do
    it "should return the data object if the response contains only one data instance" do
      expect(subject.find).to be_a(JsonAPIExampleArticle)
    end

    it "should return a Flexirest::ResultIterator if the response contains more than one data instance" do
      expect(subject.find_all).to be_a(Flexirest::ResultIterator)
    end
  end

  context "attributes" do
    it "should return the attributes as part of the data instance" do
      expect(subject.find.item).to_not be_nil
    end

    it "should return the association's attributes as part of the association instance" do
      expect(subject.find_single_author.author.item).to_not be_nil
    end
  end

  context "associations" do
    it "should retrieve the resource's associations via its relationships object" do
      expect(subject.find.tags.size).to eq(2)
    end

    it "should retrieve the response object if the relationship type is singular" do
      expect(subject.find_single_author.author).to be_a(JsonAPIAssociationExampleAuthor)
    end

    it "should retrieve a Flexirest::ResultIterator if the relationship type is plural" do
      expect(subject.find.tags).to be_a(Flexirest::ResultIterator)
    end
  end

  context "lazy loading" do
    it "should retrieve the resource by loading the url from the links object" do
      expect(lazy.find.author).to be_a(Flexirest::LazyAssociationLoader)
      expect(lazy.find.author.id).to_not be_nil
      expect(lazy.find.author.item).to_not be_nil
    end
  end

  context "client" do
    it "should request with json api format, and expect a json api response" do
      expect_any_instance_of(Flexirest::Connection).to receive(:post) { |_, _, _, options|
        expect(options[:headers]).to include("Content-Type" => "application/vnd.api+json")
        expect(options[:headers]).to include("Accept" => "application/vnd.api+json")
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{}", response_headers:{})))
      JsonAPIExample::Article.new.create
    end

    it "should perform a post request in proper json api format" do
      expect_any_instance_of(Flexirest::Connection).to receive(:post) { |_, path, data|
        hash = MultiJson.load(data)
        expect(path).to eq("/articles")
        expect(hash["data"]).to_not be_nil
        expect(hash["data"]["id"]).to be_nil
        expect(hash["data"]["type"]).to_not be_nil
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{}", response_headers:{})))
      author = JsonAPIExample::Author.new
      author.id = 1
      tag = JsonAPIExample::Tag.new
      tag.id = 1
      article = JsonAPIExample::Article.new
      article.item = "item one"
      article.author = author
      article.tags = [tag]
      article.create
    end

    it "should perform a patch request in proper json api format" do
      expect_any_instance_of(Flexirest::Connection).to receive(:patch) { |_, path, data|
        hash = MultiJson.load(data)
        expect(path).to eq("/articles/1")
        expect(hash["data"]).to_not be_nil
        expect(hash["data"]["id"]).to_not be_nil
        expect(hash["data"]["type"]).to_not be_nil
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{}", response_headers:{})))
      article = JsonAPIExample::Article.find(1)
      article.item = "item one"
      article.update
    end

    it "should perform a delete request in proper json api format" do
      expect_any_instance_of(Flexirest::Connection).to receive(:delete) { |_, path, data|
        expect(path).to eq("/articles/1")
        expect(data).to eq("{}")
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{}", response_headers:{})))
      JsonAPIExample::Article.find(1).delete
    end

    it "should have placed the right type value in the request" do
      expect_any_instance_of(Flexirest::Connection).to receive(:patch) { |_, _, data|
        hash = MultiJson.load(data)
        expect(hash["data"]["type"]).to eq(JsonAPIExample::ArticleAlias.alias_type.to_s)
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body:"{}", response_headers:{})))
      author = JsonAPIExample::ArticleAlias.find(1)
      author.item = "item one"
      author.update
    end
  end
end
