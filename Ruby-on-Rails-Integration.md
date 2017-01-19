# Ruby on Rails Integration

Flexirest works fine with Ruby on Rails Framework. This guide was tested with a Rails 4.2.x Application.


## Integration

Start referencing `flexirest` in your `Gemfile`

```ruby
# Gemfile
gem 'flexirest'
```


## Configuration

It's possible to explicit specify the `base_url` in the Model Class. If you have an common API Endpoint it makes sense to setup an initializer in `config/initializers` or use the `Rails.application.configure` namespace.

This example use a custom file in `config/initializers` to setup the API endpoint. Either set a fixed URL or use environment variables if you would like to follow the [12factor](http://12factor.net/config) rules for preparing your application running on cloud infrastructure like heroku.

```ruby
# config/initializers/flexirest.rb
Flexirest::Base.base_url = ENV.fetch("API_ENDPOINT_URL")
```


## Routes

Like every other RESTful resource, just add the controller as a reference into your routes.

```ruby
# config/routes.rb

Rails.application.routes.draw do
  # ...
  resources :people
end
```


## Model

The `ActiveModel` shortcuts will add support for `form_for` helper and `@person.errors` functionally in your views.
For example, if you have a scaffolded view structure this will just work out of the box. Read more about `ActiveModel` here:

 * [ActiveModel::Naming](http://api.rubyonrails.org/classes/ActiveModel/Naming.html)
 * [ActiveModel::Conversion](http://api.rubyonrails.org/classes/ActiveModel/Conversion.html)
 * [ActiveModel::Validations](http://api.rubyonrails.org/classes/ActiveModel/Validations.html)

In Rails, a resourceful route provides a mapping between HTTP verbs and URLs to controller actions.
Add the GET, POST, PATCH and DELETE methods that reflect to your endpoint.

Add the `persisted?` method to your Class to support Rails named_routes, so you could use `edit_person_path(person)` without explicit pass the `person.id`.


```ruby
# app/models/person.rb
class Person < Flexirest::Base

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  get    :all,     "/people"
  get    :find,    "/people/:id"
  patch  :update,  "/people/:id"
  post   :save,    "/people"
  delete :destroy, "/people/:id"

  def persisted?
    id.present?
  end

end
```


## Controller

The Controller is structured like an standard RESTful Rails Controller. Only the `update` method has
a small change about how params getting processed.

Flexirest requires the `id` inside the params hash, this is not included by default.
Easily merge the current id into the params with `person_params.merge(id: @person.id)`

No other changes had to be made for the controller.

```ruby
# app/controller/people_controller.rb
class PeopleController < ApplicationController
  before_action :set_person, only: [:show, :edit, :update, :destroy]

  def index
    @people = Person.all
  end

  def show
  end

  def new
    @person = Person.new
  end

  def edit
  end

  def create
    @person = Person.new(person_params)

    if @person.save
      redirect_to @person, notice: 'Person was successfully created.'
    else
      render :new
    end
  end

  def update
    if @person.update(person_params.merge(id: @person.id))
      redirect_to @person, notice: 'Person was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @person.destroy
    redirect_to people_url, notice: 'Person was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_person
      @person = Person.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def person_params
      params.require(:person).permit(:title, :first_name, :last_name, :email)
    end
end
```
