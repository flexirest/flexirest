module Flexirest
  class PlainResponse < ::String
    attr_accessor :_status
    attr_accessor :_headers

    def self.from_response(response)
      plain = self.new(response.body)
      plain._status = response.status
      plain._headers = response.response_headers
      plain
    end
  end
end
