module Appfuel
  module Repository
    # A mapping dsl that allows the collection of database columns to domain
    # attributes. The reason this dsl is separated from the DbEntityMapper
    # is due to the fact that we use method_missing for collecting column names
    # and don't want any incorrect method_missing calls to be confused when
    # collecting mapped values vs when defining them.
    class MappingDsl
      attr_reader :domain_name, :storage, :entries, :entry_class,
                  :container

      ADAPTERS = [:db, :yaml, :json, :hash]

      def initialize(domain_name, options = {})
        if options.is_a?(String)
          options = {db: options}
        end
        @entry_class = options[:entry_class] || MappingEntry
        @domain_name = domain_name.to_s
        @entries = []
        @storage = {}
        @container = options[:container]

        ADAPTERS.each do |type|
          @storage[type] = options[type] if options.key?(type)
        end

        if @storage.empty?
          fail "mapping must have at least one of #{ADAPTERS.join(',')}"
        end

        @storage.each do |key, value|
          fail "#{key} can not be empty" if value.to_s.empty?
        end

        fail "entity name can not be empty" if @domain_name.empty?
      end

      def map(name, domain_attr = nil, opts = {})
        domain_attr = name if domain_attr.nil?

        data = opts.merge({
          domain_name: domain_name,
          domain_attr: domain_attr,
          storage: storage,
          storage_attr: name,
          container: container,
        })

        @entries << entry_class.new(data)
      end
    end
  end
end
