require 'spec_helper'

class JsonAPIAssociationExampleAuthor < Flexirest::Base; end

class JsonAPIAssociationExampleTag < Flexirest::Base
  proxy :json_api
  has_many :authors, JsonAPIAssociationExampleAuthor
end

class JsonAPIAssociationExampleAuthor < Flexirest::Base
  proxy :json_api
  has_one :tag, JsonAPIAssociationExampleTag
end

class JsonAPIExampleArticle < Flexirest::Base
  proxy :json_api
  has_many :tags, JsonAPIAssociationExampleTag
  has_one :main_theme, JsonAPIAssociationExampleTag
  has_one :author, JsonAPIAssociationExampleAuthor
  has_many :co_authors, JsonAPIAssociationExampleAuthor

  faker1 = {
    data: {
      id: 1, type: 'articles', attributes: { item: 'item one' },
      relationships: {
        'tags' => { data: [{ id: 1, type: 'tags' }, { id: 2, type: 'tags' }] }
      }
    },
    included: [
      { id: 1, type: 'tags', attributes: { item: 'item two' } },
      { id: 2, type: 'tags', attributes: { item: 'item three' } }
    ]
  }
  faker2 = {
    data: [
      {
        id: 1, type: 'articles', attributes: { item: 'item one' },
        relationships: {
          'tags' => { data: [{ id: 1, type: 'tags' }, { id: 2, type: 'tags' }] }
        }
      },
      {
        id: 2, type: 'articles', attributes: { item: 'item four' },
        relationships: {
          'tags' => { data: [{ id: 2, type: 'tags' }] }
        }
      }
    ],
    included: [
      { id: 1, type: 'tags', attributes: { item: 'item two' } },
      { id: 2, type: 'tags', attributes: { item: 'item three' } }
    ]
  }
  faker3 = {
    data: {
      id: 1, type: 'articles', attributes: { item: 'item one' },
      relationships: { 'author' => { data: { id: 1, type: 'authors' } } }
    },
    included: [{ id: 1, type: 'authors', attributes: { item: 'item two' } }]
  }
  faker4 = {
    data: {
      id: 1, type: 'articles', attributes: { item: 'item one' },
      relationships: { 'author' => { data: { id: 1, type: 'authors' } } }
    },
    included: [
      { id: 1, type: 'authors', attributes: { item: 'item two' },
        relationships: { 'tag' => { data: { id: 1, type: 'tags' } } } },
      { id: 1, type: 'tags', attributes: { item: 'item three' } }
    ]
  }
  faker5 = {
    data: {
      id: 1, type: 'articles', attributes: { item: 'item one' },
      relationships: { 'tags' => { data: [{ id: 1, type: 'tags' }] } }
    },
    included: [
      { id: 1, type: 'tags', attributes: { item: 'item three' },
        relationships: { 'authors' => { data: [{ id: 1, type: 'authors' }] } } },
      { id: 1, type: 'authors', attributes: { item: 'item two' } }
    ]
  }
  faker6 = {
    data: {
      id: 1, type: 'articles', attributes: { item: 'item one' },
      relationships: { 'tags' => { data: [] }, 'author' => { data: nil } }
    }
  }
  faker7 = {
    data: {
      id: 1, type: 'articles', attributes: { item: 'item one' },
      relationships: {
        'tags' => { data: [{ id: 1, type: 'tags' }, { id: 2, type: 'tags' }] },
        'superman' => {
          links: {
            self: 'http://www.example.com/articles/1/relationships/superman',
            related: 'http://www.example.com/articles/1/superman'
          }
        }
      }
    },
    included: [
      { id: 1, type: 'tags', attributes: { item: 'item two' } },
      { id: 2, type: 'tags', attributes: { item: 'item three' } }
    ]
  }
  faker8 = {
    data: {
      id: 1, type: 'articles', attributes: { item: 'item one' },
      relationships: {
        'main_theme' => { data: { id: 1, type: 'tags' } },
        'co_authors' => { data: [{ id: 1, type: 'authors' }, { id: 2, type: 'authors' }] },
       }
    },
    included: [
      { id: 1, type: 'tags', attributes: { item: 'item one' } },
      { id: 1, type: 'authors', attributes: { item: 'item one' } },
      { id: 2, type: 'authors', attributes: { item: 'item two' } },
    ]
  }

  get(
    :find,
    '/articles/:id',
    fake: faker1.to_json,
    fake_content_type: 'application/vnd.api+json'
  )

  get(
    :find_all,
    '/articles',
    fake: faker2.to_json,
    fake_content_type: 'application/vnd.api+json'
  )

  get(
    :find_single_author,
    '/articles/:id',
    fake: faker3.to_json,
    fake_content_type: 'application/vnd.api+json'
  )

  get(
    :find_single_nested,
    '/articles/:id',
    fake: faker4.to_json,
    fake_content_type: 'application/vnd.api+json'
  )

  get(
    :find_multi_nested,
    '/articles/:id',
    fake: faker5.to_json,
    fake_content_type: 'application/vnd.api+json'
  )

  get(
    :no_assocs,
    '/articles/:id',
    fake: faker6.to_json,
    fake_content_type: 'application/vnd.api+json'
  )

  get(
    :not_recognized_assoc,
    '/articles/:id',
    fake: faker7.to_json,
    fake_content_type: 'application/vnd.api+json'
  )

  get(
    :custom_relationship_name,
    '/articles/:id',
    fake: faker8.to_json,
    fake_content_type: 'application/vnd.api+json'
  )
end

module JsonAPIExample
  class Author < Flexirest::Base
    proxy :json_api
    base_url 'http://www.example.com'

    author_faker = {
      data: { id: 1, type: 'authors', attributes: { item: 'item three' } }
    }

    get(
      :find_author,
      '/articles/:article_id/author',
      fake: author_faker.to_json,
      fake_content_type: 'application/vnd.api+json'
    )
  end

  class Tag < Flexirest::Base
    proxy :json_api
    base_url 'http://www.example.com'

    tags_faker = {
      data: [{ id: 1, type: 'tags', attributes: { item: 'item two' } }]
    }

    get(
      :find_tags,
      '/articles/:article_id/tags',
      fake: tags_faker.to_json,
      fake_content_type: 'application/vnd.api+json'
    )
  end

  class Article < Flexirest::Base
    base_url 'http://www.example.com'
    proxy :json_api
    has_one :author, Author
    has_many :tags, Tag

    faker = {
      data: { id: 1, type: 'articles', attributes: { item: 'item one' } }
    }

    faker_lazy = {
      data: {
        id: 1, type: 'articles', attributes: { item: 'item one' },
        relationships: {
          'tags' => {
            links: {
              self: 'http://www.example.com/articles/1/relationships/tags',
              related: 'http://www.example.com/articles/1/tags'
            }
          },
          'author' => {
            links: {
              self: 'http://www.example.com/articles/1/relationships/author',
              related: 'http://www.example.com/articles/1/author'
            }
          }
        }
      }
    }

    get(:real_index, '/articles')
    get(:real_find, '/articles/:id')

    get(
      :find_lazy,
      '/articles/:id',
      fake: faker_lazy.to_json,
      fake_content_type: 'application/vnd.api+json'
    )

    get(
      :find,
      '/articles/:id',
      fake: faker.to_json,
      fake_content_type: 'application/vnd.api+json'
    )

    post :create, '/articles', fake_content_type: 'application/vnd.api+json'

    patch(
      :update,
      '/articles/:id',
      fake_content_type: 'application/vnd.api+json'
    )

    delete(
      :delete,
      '/articles/:id',
      fake_content_type: 'application/vnd.api+json'
    )
  end

  class AuthorAlias < Flexirest::Base
    alias_type :authors
    proxy :json_api
  end

  class ArticleAlias < Flexirest::Base
    alias_type :articles
    base_url 'http://www.example.com'
    proxy :json_api
    has_one :author, AuthorAlias

    faker = {
      data: { id: 1, type: 'articles', attributes: { item: 'item one' } }
    }

    get(
      :find,
      '/articles/:id',
      fake: faker.to_json,
      fake_content_type: 'application/vnd.api+json'
    )

    patch :update, '/articles/:id'
  end
end

describe 'JSON API' do
  let(:subject) { JsonAPIExampleArticle }
  let(:article) { JsonAPIExample::Article }
  let(:tags) { JsonAPIExample::Tag }
  let(:author) { JsonAPIExample::Author }

  describe 'responses' do
    it 'should return the data object if the response contains only one data instance' do
      expect(subject.find(1)).to be_an_instance_of(JsonAPIExampleArticle)
    end

    it 'should return a Flexirest::ResultIterator if the response contains more than one data instance' do
      expect(subject.find_all).to be_an_instance_of(Flexirest::ResultIterator)
    end

    describe 'error responses' do
      subject(:make_request) { JsonAPIExample::Article.real_find(123) }

      before do
        headers = { "Content-Type" => "application/vnd.api+json" }
        expect_any_instance_of(Flexirest::Connection).
          to receive(:get).with("/articles/123", an_instance_of(Hash)).
          and_return(::FaradayResponseMock.new(OpenStruct.new(body: response_body.to_json, response_headers: headers, status: 404)))
      end

      context 'when no "data" key is present alongside the "errors" key' do
        let(:response_body) do
          {
            errors: [
              { detail: "The record identified by 123456 could not be found", }
            ]
          }
        end

        it 'should raise the relevant Flexirest error' do
          expect { make_request }.to raise_error(Flexirest::HTTPNotFoundClientException) do |exception|
            expect(exception.result.first.detail).to eq("The record identified by 123456 could not be found")
          end
        end
      end

      context 'when a "data" key is present alongside the "errors" key (although this is forbidden by the spec)' do
        let(:response_body) do
          {
            errors: [
              { detail: "The record identified by 123456 could not be found", }
            ],
            data: {}
          }
        end

        it 'should ignore the "data" key and raise the relevant Flexirest error' do
          expect { make_request }.to raise_error(Flexirest::HTTPNotFoundClientException) do |exception|
            expect(exception.result.first.detail).to eq("The record identified by 123456 could not be found")
          end
        end
      end
    end

    context 'when response has an empty "data" key' do
      let(:headers) { { "Content-Type" => "application/vnd.api+json" } }
      let(:response_body) { { data: [] } }

      it 'should return an empty array' do
        expect_any_instance_of(Flexirest::Connection).
          to receive(:get).with("/articles", an_instance_of(Hash)).
          and_return(::FaradayResponseMock.new(OpenStruct.new(body: response_body.to_json, response_headers: headers, status: 200)))

        expect(JsonAPIExample::Article.real_index.to_a).to eq([])
      end
    end
  end

  describe 'attributes' do
    it 'should return the attributes as part of the data instance' do
      expect(subject.find(1).item).to eq("item one")
    end

    it 'should return the association\'s attributes as part of the association instance' do
      expect(subject.includes(:author).find_single_author(1).author.item).to eq("item two")
    end
  end

  describe 'associations' do
    it 'should retrieve the resource\'s associations via its relationships object' do
      expect(subject.includes(:tags).find(1).tags.size).to eq(2)
    end

    it 'should retrieve the response object if the relationship type is singular' do
      expect(subject.includes(:author).find_single_author(1).author).to be_an_instance_of(JsonAPIAssociationExampleAuthor)
    end

    it 'should retrieve a Flexirest::ResultIterator if the relationship type is plural' do
      expect(subject.includes(:tags).find(1).tags).to be_an_instance_of(Flexirest::ResultIterator)
    end

    it 'should retrieve nested linked resources' do
      expect(subject.includes(author: [:tag]).find_single_nested(1).author.tag).to be_an_instance_of(JsonAPIAssociationExampleTag)
      expect(subject.includes(author: [:tag]).find_single_nested(1).author.tag.id).to_not be_nil
      expect(subject.includes(tags: [:authors]).find_multi_nested(1).tags.first.authors.first).to be_an_instance_of(JsonAPIAssociationExampleAuthor)
      expect(subject.includes(tags: [:authors]).find_multi_nested(1).tags.first.authors.first.id).to_not be_nil
    end

    it 'should retrieve a nil if the singular relationship type is empty' do
      expect(subject.includes(:author).no_assocs(1).author).to be_nil
    end

    it 'should retrieve empty array if the plural relationship type is empty' do
      expect(subject.includes(:tags).no_assocs(1).tags).to be_empty
    end

    it 'should retrieve associations that have a name that differs from their type name' do
      parsed = subject.includes(:main_theme, :co_authors).custom_relationship_name(1)
      expect(parsed.main_theme).to be_an_instance_of(JsonAPIAssociationExampleTag)
      expect(parsed.co_authors).to be_an_instance_of(Flexirest::ResultIterator)
    end
  end

  describe 'requests' do
    describe 'the `include=` parameter' do
      before { stub_request(:get, %r{example\.com/articles}) }

      context 'when using `.includes(:tags)`' do
        it 'equal "tags"' do
          JsonAPIExample::Article.includes(:tags).real_index
          expect(WebMock).to have_requested(:get, 'http://www.example.com/articles?include=tags')
        end
      end

      context 'when using `.includes(tags: [:authors, :articles])`' do
        it 'equal "tags.authors,tags.articles"' do
          JsonAPIExample::Article.includes(tags: [:authors, :articles]).real_index
          expect(WebMock).to have_requested(:get, 'http://www.example.com/articles?include=tags.authors,tags.articles')
        end
      end

      context 'when using both `.includes(:tags)` and other params in the final call' do
        it 'uses the values passed to the `includes() method`' do
          JsonAPIExample::Article.includes(:tags).real_index(filter: { author_id: 4 })
          expect(WebMock).to have_requested(:get, 'http://www.example.com/articles?filter%5Bauthor_id%5D=4&include=tags')
        end
      end

      context 'when using both `.includes(:tags)` and the :include param in final call' do
        it 'uses the values passed to the `includes() method`' do
          JsonAPIExample::Article.includes(:tags).real_index(include: "author")
          expect(WebMock).to have_requested(:get, 'http://www.example.com/articles?include=tags')
        end
      end
    end
  end

  context 'lazy loading' do
    it 'should fetch association lazily' do
      stub_request(:get, /www.example.com\/articles\/1\/tags/)
        .to_return(body: tags.find_tags(article_id: 1).to_json)
      stub_request(:get, /www.example.com\/articles\/1\/author/)
        .to_return(body: author.find_author(article_id: 1).to_json)

      expect(article.find_lazy(1).tags).to be_an_instance_of(Flexirest::LazyAssociationLoader)
      expect(article.find_lazy(1).tags.count).to be_an(Integer)
      expect(article.find_lazy(1).tags.first.id).to_not be_nil
      expect(article.find_lazy(1).author).to be_an_instance_of(JsonAPIExample::Author)
      expect(article.find_lazy(1).author.id).to_not be_nil
    end

    it 'should raise exception when an association in the response is not defined in base class' do
      expect { subject.includes(:tags).not_recognized_assoc(1) }.to raise_error(Exception)
    end
  end

  describe 'client' do
    it 'should request with json api format, and expect a json api response' do
      expect_any_instance_of(Flexirest::Connection).to receive(:post) { |_, _, _, options|
        expect(options[:headers]).to include('Content-Type' => 'application/vnd.api+json')
        expect(options[:headers]).to include('Accept' => 'application/vnd.api+json')
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body: '{}', response_headers: {})))
      JsonAPIExample::Article.new.create
    end

    it 'should be able to call #.create on class' do
      expect_any_instance_of(Flexirest::Connection).to receive(:post) { |_, path, data|
        hash = MultiJson.load(data)
        expect(path).to eq('/articles')
        expect(hash['data']).to_not be_nil
        expect(hash['data']['id']).to be_nil
        expect(hash['data']['type']).to eq('articles')
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body: '{}', response_headers: {})))
      JsonAPIExample::Article.create
    end

    it 'should be able to call #.create with params on class' do
      expect_any_instance_of(Flexirest::Connection).to receive(:post) { |_, path, data|
        hash = MultiJson.load(data)
        expect(path).to eq('/articles')
        expect(hash['data']).to_not be_nil
        expect(hash['data']['id']).to be_nil
        expect(hash['data']['type']).to eq('articles')
        expect(hash['data']['relationships']['author']['data']['type']).to eq('authors')
        expect(hash['data']['relationships']['tags']['data'].first['type']).to eq('tags')
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body: '{}', response_headers: {})))
      author = JsonAPIExample::Author.new
      tag = JsonAPIExample::Tag.new
      JsonAPIExample::Article.create(item: 'item one', author: author, tags: [tag])
    end

    it 'should perform a post request in proper json api format' do
      expect_any_instance_of(Flexirest::Connection).to receive(:post) { |_, path, data|
        hash = MultiJson.load(data)
        expect(path).to eq('/articles')
        expect(hash['data']).to_not be_nil
        expect(hash['data']['id']).to be_nil
        expect(hash['data']['type']).to eq('articles')
        expect(hash['data']['relationships']['author']['data']['type']).to eq('authors')
        expect(hash['data']['relationships']['tags']['data'].first['type']).to eq('tags')
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body: '{}', response_headers: {})))
      author = JsonAPIExample::Author.new
      tag = JsonAPIExample::Tag.new
      article = JsonAPIExample::Article.new
      article.item = 'item one'
      article.author = author
      article.tags = [tag]
      article.create
    end

    it 'should raise a Flexirest error when two different classes are in one relationship' do
      author = JsonAPIExample::Author.new
      tag = JsonAPIExample::Tag.new
      article = JsonAPIExample::Article.new
      article.item = 'item one'
      article.tags = [tag, author]
      expect { article.create }.to raise_error(Exception)
    end

    it 'should perform a patch request in proper json api format' do
      expect_any_instance_of(Flexirest::Connection).to receive(:patch) { |_, path, data|
        hash = MultiJson.load(data)
        expect(path).to eq('/articles/1')
        expect(hash['data']).to_not be_nil
        expect(hash['data']['id']).to_not be_nil
        expect(hash['data']['type']).to_not be_nil
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body: '{}', response_headers: {})))
      article = JsonAPIExample::Article.find(1)
      article.item = 'item one'
      article.update
    end

    it 'should perform a delete request in proper json api format' do
      expect_any_instance_of(Flexirest::Connection).to receive(:delete) { |_, path, data|
        expect(path).to eq('/articles/1')
        expect(data).to eq('')
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body: '{}', response_headers: {})))
      JsonAPIExample::Article.find(1).delete
    end

    it 'should have placed the right type value in the request' do
      expect_any_instance_of(Flexirest::Connection).to receive(:patch) { |_, _, data|
        hash = MultiJson.load(data)
        expect(hash['data']['type']).to eq(JsonAPIExample::ArticleAlias.alias_type.to_s)
        expect(hash['data']['relationships']['author']['data']['type']).to eq(JsonAPIExample::AuthorAlias.alias_type.to_s)
      }.and_return(::FaradayResponseMock.new(OpenStruct.new(body: '{}', response_headers: {})))
      author = JsonAPIExample::AuthorAlias.new
      author.id = 1
      article = JsonAPIExample::ArticleAlias.find(1)
      article.item = 'item one'
      article.author = author
      article.update
    end
  end
end
