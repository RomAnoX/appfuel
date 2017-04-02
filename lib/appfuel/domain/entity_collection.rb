module Appfuel
  module Domain
    # Currently this only answers the use case where a collection of active
    # record models are converted into a collection of domain entities via
    # a entity loader.
    #
    # NOTE: There is no ability yet to add or track the entity state
    #
    class EntityCollection
      include Enumerable
      attr_reader :domain_name, :domain_basename, :entity_loader

      def initialize(domain_name, entity_loader = nil)
        unless Types.key?(domain_name)
          fail "#{domain_name} is not a registered type"
        end

        @pager  = nil
        @list   = []
        @loaded = false

        parts = domain_name.split('.')
        @domain_name     = domain_name
        @domain_basename = parts.last
        @is_global       = parts.size == 1

        self.entity_loader =  entity_loader if entity_loader
      end

      def collection?
        true
      end

      def global?
        @is_global
      end

      def all
        load_entities
        @list
      end

      def first
        load_entities
        @list.first
      end

      def each
        load_entities
        return @list.each unless block_given?

        @list.each {|entity| yield entity}
      end

      def pager
        load_entities
        @pager
      end

      def to_a
        list = []
        each do |entity|
          list << entity.to_h
        end
        list
      end

      def entity_loader?
        !@entity_loader.nil?
      end

      def entity_loader=(loader)
        fail "Entity loader must implement call" unless loader.respond_to?(:call)
        @entity_loader = loader
      end

      protected

      def load_entities
        return false if @loaded || !entity_loader?
        data = entity_loader.call
        @list = data[:list]
        @pager  = data[:pager]
      end
    end
  end
end
