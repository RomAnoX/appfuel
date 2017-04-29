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

        fail "options must be a hash" unless options.is_a?(Hash)

        @entry_class = options[:entry_class] || MappingEntry
        @domain_name = domain_name.to_s
        @entries = []
        @storage = {}
        @container = options[:container]
        @storage = translate_storage_keys(options)

        if @storage.empty?
          fail "mapping must have at least one of #{ADAPTERS.join(',')}"
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

      private

      #
      # global.user
      # global.storage.db.user
      # membership.user
      # features.membership.storage.{type}.user
      def translate_storage_keys(storage_hash)
        hash = {}
        ADAPTERS.each do |type|
          next unless storage_hash.key?(type)
          partial_key = storage_hash[type].to_s
          if partial_key.empty?
            fail "#{type} can not be empty"
          end

          top, *parts = partial_key.split('.')

          top = "features.#{top}" unless top == 'global'
          hash[type] = "#{top}.storage.#{type}.#{parts.join('.')}"
        end
        hash
      end
    end
  end
end
