# Takes a hash of string and file parameters and returns a string of text
# formatted to be sent as a multipart form post.
#
# Author:: Cody Brimhall <mailto:brimhall@somuchwit.com>
# Created:: 22 Feb 2008
# License:: Distributed under the terms of the WTFPL (http://www.wtfpl.net/txt/copying/)

require 'rubygems'
require 'mime/types'

module Flexirest
  module Multipart
    VERSION = "1.0.0"

    class Post
      BOUNDARY = "FLEXIRESTBOUNDARY-20190918-FLEXIRESTBOUNDARY"
      CONTENT_TYPE = "multipart/form-data; boundary=#{BOUNDARY}"
      HEADER = {"Content-Type" => CONTENT_TYPE}

      def self.prepare_query(params)
        fp = []

        params.stringify_keys.each do |k, v|
          append_parameter(fp, k, v)
        end

        query = fp.collect {|p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
        return query, HEADER
      end

      def self.append_parameter(fp, key, value)
        if value.is_a?(Array)
          value.each do |i|
            append_parameter(fp, "#{key}[]", i)
          end
        elsif value.is_a?(Hash)
          value.stringify_keys.each do |k, i|
            append_parameter(fp, "#{key}[#{k}]", i)
          end
        elsif value.respond_to?(:path) and value.respond_to?(:read) then
          fp.push(FileParam.new(key, value.path, value.read))
        else
          fp.push(StringParam.new(key, value))
        end

      end
    end

    private

    class StringParam
      attr_accessor :k, :v

      def initialize(k, v)
        @k = k
        @v = v
      end

      def to_multipart
        return "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
      end
    end

    class FileParam
      attr_accessor :k, :filename, :content

      def initialize(k, filename, content)
        @k = k
        @filename = filename
        @content = content
      end

      def to_multipart
        mime_type = MIME::Types.type_for(filename)[0] || MIME::Types["application/octet-stream"][0]
        return "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" +
               "Content-Type: #{ mime_type.simplified }\r\n\r\n#{ content }\r\n"
      end
    end
  end
end
