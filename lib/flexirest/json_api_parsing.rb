module Flexirest
  module JsonAPIParsing
    def json_api_create_params(params, object, options = {})
      type_name = options[:type_name] || class_type_name(object.class)
      _params = Parameters.new(object.id, type_name)
      params.delete(:id)

      params.map do |k, v|
        if v.is_a?(Array)
          # Should always contain the same class in entire list
          raise Flexirest::Logger.error("Cannot contain different instances for #{k}!") if v.map(&:class).count > 1
          v.each do |el|
            _params.add_relationship(k, class_type_name(el.class), el[:id])
          end
        elsif v.is_a?(Flexirest::Base)
          _params.add_relationship(k, class_type_name(v.class), v[:id])
        else
          _params.add_attribute(k, v)
        end
      end

      _params.to_hash
    end

    def json_api_parse_response(body)
      included = body["included"]
      records = body["data"]

      return records unless records.present?

      is_singular_record = records.is_a?(Hash)
      records = [records] if is_singular_record

      base = records.first["type"]

      if records.first["relationships"]
        rels = records.first["relationships"].keys
      end

      bucket = records.map do |record|
        retrieve_attributes_and_relations(base, record, included, rels)
      end

      is_singular_record ? bucket.first : bucket
    end

    private

    def retrieve_attributes_and_relations(base, record, included, rels)
      rels ||= []
      rels -= [base]
      base = record["type"]
      relationships = record["relationships"]

      rels.each do |rel|
        if singular?(rel)
          unless relationships[rel]["data"]
            begin
              record[rel] = relationships[rel]["links"]["related"]
            rescue NoMethodError
              record[rel] = nil
            end
            next record
          end

          rel_id = relationships[rel]["data"]["id"]
          record[rel] = included.select { |i| i["id"] == rel_id && i["type"] == rel.singularize }

        else
          unless relationships[rel]["data"]
            begin
              record[rel] = relationships[rel]["links"]["related"]
            rescue NoMethodError
              record[rel] = []
            end
            next record
          end

          rel_ids = relationships[rel]["data"].map { |r| r["id"] }
          record[rel] = included.select { |i| rel_ids.include?(i["id"]) && i["type"] == rel.singularize }
        end

        relations = record[rel].map do |subrecord|
          retrieve_attributes(subrecord)
          next subrecord unless subrecord["relationships"]

          subrels = subrecord["relationships"].keys
          next subrecord if subrels.empty?

          retrieve_attributes_and_relations(base, subrecord, included, subrels)
        end

        record[rel] = singular?(rel) ? relations.first : relations
      end

      retrieve_attributes(record)
      record
    end

    def retrieve_attributes(record)
      record["attributes"].each do |k, v|
        record[k] = v
      end

      delete_json_api_keys(record)
    end

    def singular?(word)
      w = word.to_s
      w.singularize == w && w.pluralize != w
    end

    def delete_json_api_keys(r)
      r.delete("type")
      r.delete("attributes")
      r.delete("relationships")
    end

    def class_type_name(klass)
      klass.name.underscore.split('/').last
    end

    class Parameters
      include Flexirest::JsonAPIParsing
      def initialize(id, type)
        @params = build(id, type)
      end

      def to_hash
        @params
      end

      def add_relationship(name, type_name, id)
        if singular?(name)
          @params[:data][:relationships][name] = {
            data: { type: type_name, id: id }
          }
        else
          if @params[:data][:relationships][name]
            @params[:data][:relationships][name][:data] << {
              type: type_name, id: id
            }
          else
            @params[:data][:relationships][name] = {
              data: [ { type: type_name, id: id } ]
            }
          end
        end
      end

      def add_attribute(key, value)
        @params[:data][:attributes][key] = value
      end

      private

      def build(id, type)
        pp = {}
        pp[:data] = {}
        pp[:data][:id] = id if id
        pp[:data][:type] = type
        pp[:data][:attributes] = {}
        pp[:data][:relationships] = {}
        pp
      end
    end
  end
end
