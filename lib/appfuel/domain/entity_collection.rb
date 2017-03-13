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
      attr_reader :domain_name, :entity_loader

      def initialize(domain_name, entity_loader = nil)
        unless Types.key?(domain_name)
          fail "#{domain_name} is not a registered type"
        end

        @list          = []
        @domain_name   = domain_name
        @loaded        = false
        @page_size     = nil
        @total_count   = nil
        @total_pages   = nil
        @current_page  = nil
        self.entity_loader =  entity_loader if entity_loader
      end

      def total_pages
        load_entities
        @total_pages
      end

      def current_page
        load_entities
        @current_page
      end

      def total_count
        load_entities
        @total_count
      end

      def page_size
        load_entities
        @page_size
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

      def to_hash
        data = {
          total_pages: total_pages,
          current_page: current_page,
          total_count: total_count,
          page_size: page_size,
          items: []
        }
        each do |entity|
          data[:items] << entity.to_h
        end
        data
      end

      def to_h
        to_hash
      end

      def to_json
        to_hash.to_json
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

        data          = entity_loader.call
        @list         = data[:items] || []
        @total_pages  = data[:total_pages]
        @current_page = data[:current_page]
        @total_count  = data[:total_count]
        @page_size    = data[:page_size]
      end
    end
  end
end
