module Appfuel
  module Memory
    class Repository < Appfuel::Repository::Base

      class << self
        def create_mapper(maps = nil)
          Mapper.new(maps)
        end
      end

      attr_reader :items, :sequence
      def initialize
        @items    = {}
        @sequence = 0
      end


      def create(entity)
        id = sequence_id
        entity.id = id
        data = to_storage(entity)
        ap "data for to_storage is"
        ap data
        items[id] = data


        build(entity.domain_name, data, :hash)
      end

      def sequence_id
        @sequence + 1
      end
    end
  end
end
