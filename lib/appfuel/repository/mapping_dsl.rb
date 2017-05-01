module Appfuel
  module Repository
    # A mapping dsl that allows the collection of database columns to domain
    # attributes. The reason this dsl is separated from the DbEntityMapper
    # is due to the fact that we use method_missing for collecting column names
    # and don't want any incorrect method_missing calls to be confused when
    # collecting mapped values vs when defining them.
    class MappingDsl
      attr_reader :domain_name, :storage, :entries, :entry_class,
                  :container_name

      STORAGE_TYPES = [:db, :file, :memory]

      # 1) mapping 'feature.domain', db: true, do
      #    ...
      #    end
      #
      # 2) mapping 'feature.domain', db: 'foo.bar', do
      #    ...
      #    end
      #
      # 3) mapping 'feature.domain', db: 'global.bar' do
      #    ...
      #    end
      #
      # 4) mapping 'feature.domain', db: 'foo.bar.baz', key_translation: false)
      # 4) mapping 'feature.domain', storage: [:db, :file] do
      #    ...
      #    end
      #
      # 5) mapping 'feature.domain' db: true do
      #       storage :file, path: '/foo/bar/bar, model: foo.bar
      #    end
      #
      # 6) mapping 'feature.domain', db: true do
      #      storage :file, true
      #    end
      #
      # a file model requires the domain_name it represents.
      #
      #   case1 - build a model with default settings
      #   file: storage.file.model
      #           path: <root_path>/storage/file/{key}.yaml
      #           adapter: storage.file.model
      #
      #   case2 - build a model with given settings
      #           note: if path is absolute nothing is done
      #                 if path is relative we will prepend root_path
      #                 if no yaml extension the key is translated to a path
      #
      #           path: foo/bar/baz.yml -> <root_path>/foo/bar/baz.yml
      #           path: /foo/bar/baz.yml -> /foo/bar/baz.yml
      #           path  auth.user -> <root_path>/storage/features/auth/file/user.yml
      #           path gobal.user -> <root_path/storage/global/auth/file/user.yml
      #
      #   case3 - build a model with adapter and path
      #     path: sames as above
      #     adapter translates key to location of adapter in storage
      #
      #     container
      #         default key -> storage.file.model is default
      #         auth.user -> features.auth.storage.file.user
      #
      # file 'storage.file.model'
      #
      # storage db: 'foo.user_user'
      # storage :file
      # storage :memory
      #
      # storage db: 'foo.user_ath',
      #         file: 'storage.file.model',
      #         memory: 'storage.memory.model'
      #
      def initialize(domain_name, options = {})
        if options.is_a?(String)
          options = {db: options}
        end

        fail "options must be a hash" unless options.is_a?(Hash)

        @entries        = []
        @domain_name    = domain_name.to_s
        @entry_class    = options[:entry_class] || MappingEntry
        @container_name = options[:container] || Appfuel.default_app_name
        @storage        = initialize_storage(options)

        fail "entity name can not be empty" if @domain_name.empty?
      end

      def db(key)
        @storage[:db] = translate_storage_key(key)
      end

      def storage(data = nil)
        return @storage if data.nil?

        assign_default_storage(data) if data.is_a?(Symbol)

        unless data.is_a?(Hash)
          fail "Storage must be a symbol or a hash :type => 'container_key'"
        end

        data.each {|type, partial_key| assign_storage(type, partial_key)}

      end

      def map(name, domain_attr = nil, opts = {})
        domain_attr = name if domain_attr.nil?

        data = opts.merge({
          domain_name: domain_name,
          domain_attr: domain_attr,
          storage: storage,
          storage_attr: name,
          container: container_name,
        })

        @entries << entry_class.new(data)
      end

      private

      def initialize_storage(data)
        storage = {}
        if data.key?(:db)
          value = data[:db]
          if value == true
            storage[:db] = translate_storage_key('db', domain_name)
          elsif data.key?(:key_translation) && data[:key_translation] == false
            storage[:db] = value
          elsif
            storage[:db] = translate_storage_key('db', value)
          end
        elsif data.key?(:file)
          value = data[:file]
          if value == true
            key = translate_storage_key('file', domain_name)
            storage[:file] = {
              model: 'storage.file.model',
              path: "#{storage_path}/#{key.gsub(/\./,'/')}.yml"
            }
          end
        elsif data.key?(:storage) && data[:storage].is_a?(Array)
          data[:storage].each do |type|
            storage.merge!(initialize_storage(type => true))
          end
        end
        storage
      end

      def storage_path
        app_container = Appfuel.app_container(container_name)
        path = app_container[:root_path]
        if app_container.key?(:storage_path)
          path = app_container[:storage_path]
        end
        path
      end

      #
      # global.user
      # global.storage.db.user
      # membership.user
      # features.membership.storage.{type}.user
      def translate_storage_key(type, partial_key)
        fail "#{type} can not be empty" if partial_key.empty?

        top, *parts = partial_key.split('.')
        top = "features.#{top}" unless top == 'global'
        "#{top}.storage.#{type}.#{parts.join('.')}"
      end

      def assign_storage(type, partial_key)
        @storage[type] = translate_storage_key(partial_key)
      end

      def assign_default_storage(type)
        @storage[type] = "storage.#{type.to_s.underscore}.model"
      end
    end
  end
end
