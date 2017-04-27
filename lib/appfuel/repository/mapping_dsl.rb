module Appfuel
  module Repository
    # A mapping dsl that allows the collection of database columns to domain
    # attributes. The reason this dsl is separated from the DbEntityMapper
    # is due to the fact that we use method_missing for collecting column names
    # and don't want any incorrect method_missing calls to be confused when
    # collecting mapped values vs when defining them.
    class MappingDsl
      attr_reader :domain_name, :persistence, :entries, :entiry_class

      def initialize(domain_name, options = {})
        @entry_class = options[:entrty_class] || MappingEntry
        @domain_name = domain_name.to_s
        @entries = []
        classes = options.fetch(:persistence)
        classes = {db: classess} if classes.is_a?(String)
        if !classes.is_a?(Hash) || classes.empty?
          fail ":persistence must be a string or non empty hash"
        end

        @persistence = classes

        fail "entity name can not be empty" if @domain_name.empty?
      end

      def map(name, entity_attr = nil, opts = {})
        entity_attr = name if entity_attr.nil?

        data = opts.merge({
          domain_name: domain_name,
          domain_attr: domain_attr,
          persistence: persistence,
          persistence_attr: name,
        })

        @entries << entry_class.new(data)
      end
    end
  end
end
