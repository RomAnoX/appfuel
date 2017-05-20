module Appfuel
  module Memory
    class Repository < Appfuel::Repository::Base

      class << self
        def container_class_type
          "#{super}.memory"
        end

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
        items[id] = data


        build(name: entity.domain_name, storage: data)
      end

      def build(name:, storage:, **inputs)
        super(type: :memory, name: name, storage: storage,  **inputs)
      end

      def sequence_id
        @sequence + 1
      end
    end
  end
end
