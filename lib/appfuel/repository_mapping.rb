module Appfuel
  module RepositoryMapping
    module ClassMethods
      attr_accessor :mapper
      attr_writer :map_dsl_class, :mapper_class, :map_class

      def mapper?
        !mapper.nil?
      end

      # The map dsl handles all the logic needed to map one or more tables
      # to a given entity. This allows you to change to your own dsl if
      # needed.
      #
      # @return [DbEntityMapDsl]
      def map_dsl_class
        @map_dsl_class ||= DbEntityMapDsl
      end

      # The mapper class manages all the maps for one or more entities.
      # A repo can only have one mapper. The mapper basically delegates
      # call to one or all maps
      #
      # @return [DbEntityMapper]
      def mapper_class
        @mapper_class ||= DbEntityMapper
      end

      # The map class represents a single map between an ActiveRecord model
      # (table in the database) and an entity or part of an entity since we
      # can map more than one table to a single entity
      #
      # @return [DbEntityMap]
      def map_class
        @map_class ||= DbEntityMap
      end

      # Mapping uses the map_dsl_class, map_class and mapper_class to define
      # build and assign a map into a mapper. If the mapper does not exist
      # then one is created and maps are added to that.
      #
      # @example Simple mapping
      #   mapping 'offers.offer', db: v3_offer do
      #     map 'id'
      #     map 'project_user_id', 'user.id'
      #   end
      #
      #   Note: When no :key value is given to options then the entity base
      #         name is used. The following would be equivalent:
      #
      #   mapping 'offers.offer', key: 'offer', db: v3_offer do
      #     ...
      #   end
      #
      # @example Implied db table
      #
      # @param entity_name [String] domain name of the entity we are mapping
      # @param opts [Hash] options to configure map
      # @option opts [String] :db active record model we are mapping, required
      # @option opts [String] :key map key used to identify this map
      #
      # @return [DbEntityMapper]
      def mapping(entity_name, opts, &block)
        fail "opts must be a hash" unless opts.is_a?(Hash)
        fail "[:db] db model name is required " unless opts.key?(:db)

        dsl = map_dsl_class.new(entity_name, opts[:db], opts[:key])
        dsl.instance_eval(&block)

        unless mapper?
          self.mapper = mapper_class.new(dsl, map_class)
        else
          mapper << dsl
        end
        mapper
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
