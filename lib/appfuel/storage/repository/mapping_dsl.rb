module Appfuel
  module Repository
    # A mapping dsl that allows the collection of database columns to domain
    # attributes. The reason this dsl is separated from the DbEntityMapper
    # is due to the fact that we use method_missing for collecting column names
    # and don't want any incorrect method_missing calls to be confused when
    # collecting mapped values vs when defining them.
    class MappingDsl
      attr_reader :domain_name, :entries, :map_class, :container_name,
                  :storage_key, :storage_type

      # 1) mapping 'feature.domain', to: :db, model: 'foo.db.bar', contextual_key: false do
      #
      #    end
      #
      #    mapping 'feature.domain' web_api: 'web_api.http.model' do
      #     map 'id'
      #     map 'foo', 'bar'
      #     map 'biz', 'baz'
      #    end
      #
      def initialize(domain_name, to:, model:, **opts)
        opts          ||= {}
        @entries        = []
        @domain_name    = domain_name.to_s
        @map_class      = opts[:map_class] || StorageMap
        @container_name = opts[:container] || Appfuel.default_app_name

        @contextual_key = true
        if opts.key?(:contextual_key) && opts[:contextual_key] == false
          @contextual_key = false
        end
        @storage_type = to
        @storage_key  = translate_storage_key(to, model)

        fail "entity name can not be empty" if @domain_name.empty?
      end

      def create_storage_map
        ap map_class
        StorageMap.new(
          domain_name:    domain_name,
          container_name: container_name,
          storage_type:   storage_type,
          storage_key:    storage_key,
          entries:        entries
        )
      end

      def map(name, domain_attr = nil, opts = {})
        if domain_attr.is_a?(Hash)
          opts = domain_attr
          domain_attr = nil
        end

        domain_attr = name if domain_attr.nil?

        data = opts.merge({
          domain_attr: domain_attr,
          storage_attr: name,
        })

        entries << data
      end

      def contextual_key?
        @contextual_key
      end

      # global.user
      # global.storage.db.user
      # membership.user
      # features.membership.{type}.user
      def translate_storage_key(type, partial_key)
        return partial_key unless contextual_key?
        fail "#{type} model key can not be empty" if partial_key.empty?

        # take the feature or domain root unless its global
        domain_top, _domain_base = domain_name.split('.')
        top, *parts = partial_key.split('.')

        if top == 'global'
          root = top
          base = parts.join('.')
        else
          root = "features.#{domain_top}"
          base = top
        end

        "#{root}.#{type}.#{base}"
      end
    end
  end
end
