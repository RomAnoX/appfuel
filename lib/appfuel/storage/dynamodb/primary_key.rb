module Appfuel
  module Dynamodb
    class PrimaryKey
      attr_reader :hash_key, :range_key

      def initialize(hash_key, hash_type, range_key = nil, range_type = nil)
        @hash_key = hash_key.to_sym
        @hash_type = hash_type
        unless range_key.nil?
          if range_type.nil?
            fail "range_type is required for primary range key"
          end
          @range_key = range_key
          @range_type = range_type
        end
      end

      def composite?
        !range_key.nil?
      end

      def params(hash_value, range_value = nil)
        data = { hash_key => hash_value }
        if composite?
          if range_value.nil?
            fail "This is a composite key range_value is required"
          end
          data[range_key] = range_value
        end
        data
      end
    end
  end
end
