# frozen_string_literal: true

module Flexirest
  # JSON API requests and responses
  module JsonAPIProxy
    @object ||= nil
    @headers ||= {}

    # Methods used across other modules
    module Helpers
      def singular?(word)
        w = word.to_s
        w.singularize == w && w.pluralize != w
      end

      def type(object)
        # Retrieve the type value for JSON API from the Flexirest::Base class
        # If `alias_type` has been defined within the class, use it
        name = object.alias_type || object.class.alias_type

        # If not, guess the type value from the class name itself
        return object.class.name.underscore.split('/').last unless name
        name
      end
    end

    # Creating JSON API requests
    module Request
      # Creating and formatting JSON API parameters
      module Params
        extend self
        extend Flexirest::JsonAPIProxy::Helpers

        def create(params, object)
          # Create a parameters object with the resource's type value and id
          parameters = Parameters.new(object.id, type(object))

          # Remove id attribute from top-level hash, this will be included
          # in the resource object
          params.delete(:id)

          # Build the JSON API compliant parameters
          parameters.create_from_hash(params)

          # Return the parameters as a hash, so it can be used elsewhere
          parameters.to_hash
        end

        def translate(params, include_associations)
          # Return to caller if nothing is to be done
          return params unless params.present? && include_associations.present?

          # Format the linked resources array, and assign to include key
          params[:include] = format_include_params(include_associations)
        end

        private

        def format_include_params(associations)
          includes = []

          associations.each do |key|
            # Format each association name
            # if the key is a nested hash, format each nested association too
            # e.g. [author, comments.likes]

            if key.is_a?(Hash)
              # Create a link from each association to nested association
              key.each { |k, val| val.each { |v| includes << "#{k}.#{v}" } }

            else
              # Just convert the association to string, in case it is a Symbol
              includes << key.to_s
            end
          end

          # Join the includes array with comma separator
          includes.join(',')
        end

        # Private class for building JSON API compliant parameters
        class Parameters
          include Flexirest::JsonAPIProxy::Helpers

          def initialize(id, type)
            @params = build(id, type)
          end

          def to_hash
            @params
          end

          def create_from_hash(hash)
            hash.each do |k, v|
              # Build JSON API compliant parameters from each key and value
              # in the standard-style parameters hash

              if v.is_a?(Array)
                # This is a one-to-many relationship
                validate_relationships!(v)

                # Add a relationship object for all related resources
                v.each { |el| add_relationship(k, type(el), el.id) }

              elsif v.is_a?(Flexirest::Base)
                # This is a one-to-one relationship
                add_relationship(k, type(v), v.id)

              else
                # This is a normal attribute
                add_attribute(k, v)
              end
            end
          end

          def add_relationship(name, type, id)
            # Use the `name` parameter to determine the type of relationship

            if singular?(name)
              # If `name` is a singular word (one-to-one relationship),
              # add or overwrite the data object for the given `name`,
              # containing a type and id value to the relationships object
              @params[:data][:relationships][name] =
                { data: { type: type, id: id } }

            elsif @params[:data][:relationships][name]
              # If `name` is a plural word (one-to-many relationship),
              # and the `name` object already exists in the relationships object,
              # assume a nested data array exists, and add a new data object
              # containing a type and id value to the data array
              @params[:data][:relationships][name][:data] <<
                { type: type, id: id }

            else
              # If `name` is a plural word, but the `name` object does not exist,
              # add a new `name` object containing a data array,
              # which consists of exactly one data object with the type and id
              @params[:data][:relationships][name] =
                { data: [{ type: type, id: id }] }
            end
          end

          def add_attribute(key, value)
            # Add a resource attribute to the attributes object
            # within the resource object
            @params[:data][:attributes][key] = value
          end

          def build(id, type)
            # Build the standard resource object
            pp = {}
            pp[:data] = {}
            pp[:data][:id] = id if id
            pp[:data][:type] = type
            pp[:data][:attributes] = {}
            pp[:data][:relationships] = {}
            pp
          end

          def validate_relationships!(v)
            # Should always contain the same class in entire relationships array
            raise_params_error! if v.map(&:class).count > 1
          end

          def raise_params_error!
            raise Flexirest::Logger.error(
              "Cannot contain different instances for #{k}!"
            )
          end
        end
      end
    end

    # Creating JSON API header
    module Headers
      extend self
      def save(headers)
        # Save headers used in a request for building lazy association
        # loaders when parsing the response
        @headers = headers
      end
    end

    # Parsing JSON API responses
    module Response
      extend self
      extend Flexirest::JsonAPIProxy::Helpers

      def save_resource_class(object)
        @resource_class = object.is_a?(Class) ? object : object.class
      end

      def parse(body, object)
        # Save resource class for building lazy association loaders
        save_resource_class(object)

        # Retrieve the resource(s) object or array from the data object
        records = body['data']
        return records unless records.present?

        # Convert the resource object to an array,
        # because it is easier to work with an array than a single object
        # Also keep track if record is singular or plural for the result later
        is_singular_record = records.is_a?(Hash)
        records = [records] if is_singular_record

        # Retrieve all names of linked relationships
        if records.first['relationships']
          relationships = records.first['relationships'].keys
        end

        resource_type = records.first['type']
        included = body['included']

        # Parse the records, and retrieve all resources in a
        # (nested) array of resources that is easy to work with in Flexirest
        resources = records.map do |record|
          fetch_attributes_and_relationships(
            resource_type, record, included, relationships
          )
        end

        # Depending on whether we got a resource object (hash) or array
        # in the beginning, return to the caller with the same type
        is_singular_record ? resources.first : resources
      end

      private

      def fetch_attributes_and_relationships(base, record, included, rels)
        rels = (rels || []) - [base]
        rels_object = record['relationships']

        rels.each do |rel_name|
          # Determine from `rel_name` (relationship name) whether the
          # linked resource is a singular or plural (one-to-one or
          # one-to-many, respectively)
          is_singular_rel = singular?(rel_name)

          if is_singular_rel
            # Fetch a linked resource from the relationships object
            # and add it as an association attribute in the resource hash
            record[rel_name], embedded = fetch_one_to_one(
              rels_object, rel_name, included
            )

          else
            # Fetch linked resources from the relationships object
            # and add it as an array into the resource hash
            record[rel_name], embedded = fetch_one_to_many(
              rels_object, rel_name, included
            )
          end

          # Do not try to fetch embedded results if the response is not
          # a compound document. Instead, a LazyAssociationLoader should
          # have been created and inserted into the record
          next record unless embedded

          # Recursively fetch the relationships and embedded nested resources
          linked_resources = record[rel_name].map do |nested_record|
            # Find the relationships object in the linked resource
            # and find whether there are any nested linked resources
            nested_rels_object = nested_record['relationships']

            if nested_rels_object && nested_rels_object.keys.present?
              # Fetch the linked resources and its attributes recursively
              fetch_attributes_and_relationships(
                record['type'], nested_record, included, nested_rels_object.keys
              )

            else
              # If there are no nested linked resources, just fetch the
              # resource attributes of the linked resource
              fetch_and_delete_attributes(nested_record)
            end
          end

          # Depending on if the resource is singular or plural, add it as
          # the original type (array or hash) into the record hash
          record[rel_name] =
            if is_singular_rel
              linked_resources.first
            else
              linked_resources
            end
        end

        # Add the record attributes to the record hash
        fetch_and_delete_attributes(record)
        record
      end

      def fetch_one_to_one(relationships, name, included)
        # Parse the relationships object given the relationship name `name`,
        # and look into the included object (in case of a compound document),
        # to embed the linked resource into the response

        if included.blank? || relationships[name]['data'].blank?
          begin
            # When the response is not a compound document (i.e. there is no
            # includes object), build a LazyAssociationLoader for lazy loading
            return build_lazy_loader(
              name, relationships[name]['links']['related']
            ), false
          rescue NoMethodError
            # If the url for retrieving the linked resource is missing,
            # we assume there is no linked resource available to fetch
            # Default nulled linked resource is `nil`
            return nil, false
          end
        end

        # Retrieve the linked resource id and its pluralized type name
        rel_id = relationships[name]['data']['id']
        plural_name = name.pluralize

        # Traverse through the included object, and find the included
        # linked resource, based on the given id and pluralized type name
        linked_resource = included.select do |i|
          i['id'] == rel_id && i['type'] == plural_name
        end

        return linked_resource, true
      end

      def fetch_one_to_many(relationships, name, included)
        # Parse the relationships object given the relationship name `name`,
        # and look into the included object (in case of a compound document),
        # to embed the linked resources into the response

        if included.blank? || relationships[name]['data'].blank?
          begin
            # When the response is not a compound document (i.e. there is no
            # includes object), build a LazyAssociationLoader for lazy loading
            return build_lazy_loader(
              name, relationships[name]['links']['related']
            ), false
          rescue NoMethodError
            # If the url for retrieving the linked resources is missing,
            # we assume there are no linked resources available to fetch
            # Default nulled linked resources is an empty array
            return [], false
          end
        end

        # Retrieve the linked resources ids
        rel_ids = relationships[name]['data'].map { |r| r['id'] }

        # Traverse through the included object, and find the included
        # linked resources, based on the given ids and type name
        linked_resources = included.select do |i|
          rel_ids.include?(i['id']) && i['type'] == name
        end

        return linked_resources, true
      end

      def fetch_and_delete_attributes(record)
        # Fetch attribute keys and values from the resource object
        # and insert into result record hash
        record['attributes'].each do |k, v|
          record[k] = v
        end

        delete_keys(record)
        record
      end

      def delete_keys(record)
        # Delete the attribute keys and values from the original response hash
        record.delete('type')
        record.delete('links')
        record.delete('attributes')
        record.delete('relationships')
      end

      def build_lazy_loader(name, url)
        # Create a new request, given the linked resource `name`,
        # finding the association's class, and given the `url` to the linked
        # resource

        request = Flexirest::Request.new(
          { url: url, method: :get },
          @resource_class._associations[name.to_sym].new
        )

        # Also add the previous request's header, which may contain
        # crucial authentication headers (or so), to connect with the service
        request.headers = @headers
        request.url = request.forced_url = url

        Flexirest::LazyAssociationLoader.new(name, url, request)
      end
    end
  end
end
