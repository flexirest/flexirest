module Flexirest
  module JsonAPIParsing
    private

    def parse_json_api(body)
      included = body["included"]
      records = body["data"]

      return records unless records.present?

      is_singular_record = records.is_a?(Hash)
      records = [records] if is_singular_record

      base = records.first["type"]

      if records.first["relationships"]
        rels = records.first["relationships"].keys
      end

      if included
        bucket = records.map do |record|
          retrieve_attributes_and_relations(base, record, included, rels)
        end
      else
        # TODO Lazy loading with links
        bucket = records.map do |record|
          (rels || []).each do |rel|
            record[rel] = singular?(rel) ? nil : []
          end
          record
        end
      end

      is_singular_record ? bucket.first : bucket
    end

    def retrieve_attributes_and_relations(base, record, included, rels)
      rels -= [base]
      base = record["type"]
      relationships = record["relationships"]

      rels.each do |rel|
        if singular?(rel)
          unless relationships[rel]["data"]
            record[rel] = nil
            next record
          end

          rel_id = relationships[rel]["data"]["id"]
          record[rel] = included.select { |i| i["id"] == rel_id && i["type"] == rel.singularize }

        else
          unless relationships[rel]["data"]
            record[rel] = []
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
  end
end
