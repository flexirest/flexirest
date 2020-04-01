module Flexirest
  module AttributeParsing
    private

    def parse_attribute_value(v)
      return v if v.is_a?(Date) || v.is_a?(DateTime) ||
                  v.kind_of?(NilClass) || v.kind_of?(TrueClass) || v.kind_of?(FalseClass) || v.kind_of?(Numeric)

      if v.to_s[(/\A(((19|20)\d\d[- \/.](0[1-9]|1[012]|[1-9])[- \/.](0[1-9]|[12][0-9]|3[01]|[1-9]))|((0[1-9]|1[012]|[1-9])[- \/.](0[1-9]|[12][0-9]|3[01]|[1-9])[- \/.](19|20)\d\d))\Z/)]
        Date.parse(v) rescue v
      elsif v.to_s[/\A([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?))\Z/]
        DateTime.parse(v) rescue v
      else
        v
      end
    end
  end
end
