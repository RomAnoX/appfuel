module Appfuel
  module Domain
    class OrderExpr < Expr

      def self.build(data)
        data = [data] if data.is_a?(String)
        unless data.respond_to?(:each)
          fail "order must be a string or implement :each"
        end

        results = []
        data.each do |item|
          item = parse_order_string(item) if item.is_a?(String)
          if !item.is_a?(Hash)
            fail "order array must be a list of strings or hashes"
          end
          domain_attr, dir = item.first
          results << self.new(domain_attr, dir)
        end
        results
      end

      def initialize(domain_attr, op = 'asc')
        super(domain_attr, op, nil)
        @op = @op.downcase
        unless ['asc', 'desc'].include?(@op)
          fail "order direction must be either asc or desc"
        end
      end

      def to_s
        "#{attr_list.join('.')} #{op}"
      end

      private
      def self.parse_order_string(str)
        str, dir = str.split(' ')
         dir = 'asc' if dir.nil?
         {str => dir.downcase}
      end
    end
  end
end
