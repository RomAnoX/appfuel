require 'parslet'

module Appfuel
  module Domain
    # A PEG (Parser Expression Grammer) transformer for our domain language.
    #
    class ExprTransform < Parslet::Transform
      rule(integer:  simple(:n))  { Integer(n) }
      rule(float:    simple(:n))  { Float(n) }
      rule(boolean:  simple(:b))  { b.downcase == 'true' }
      rule(datetime: simple(:dt)) { Time.parse(dt) }
      rule(date:     simple(:d))  { Date.parse(d) }
      rule(string:   simple(:s)) do
        s.to_s.gsub(/\\[0tnr]/, "\\0" => "\0",
                                "\\t" => "\t",
                                "\\n" => "\n",
                                "\\r" => "\r")
      end

      rule(domain: subtree(:value)) do
        if value.is_a?(Hash)
          data = [ value[:attr_label].to_s ]
        else
          data = []
          value.each do |label|
            data << label[:attr_label].to_s
          end
        end
        {domain: data}
      end
    end
  end
end
