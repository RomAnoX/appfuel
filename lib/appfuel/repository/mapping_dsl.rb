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

      # 5) mapping 'feature.domain' db: true do
      #    end
      #
      # 6) mapping 'feature.domain', db: true do
      #      storage :db, 'foo.bar'
      #      storage :file
      #    end
      #  storage(type = nil, options = {})
      #
      def storage(type = nil, *args)
        return @storage if type.nil?
        unless type.respond_to?(:to_sym)
          fail "Storage type must implement :to_sym"
        end
        type = type.to_sym

        if all_storage_symbols?(*args)
          args.unshift(type)
          args.each do |storage_type|
            @storage[storage_type] = send("initialize_#{storage_type}_storage", true)
          end

          return self
        end

        args = [true] if args.empty?

        key  = args.shift
        opts = args.shift
        data = {type => key}
        if opts.is_a?(Hash)
          data.merge!(opts)
        end

        @storage.merge!(initialize_storage(data))
        self
      end

      def all_storage_symbols?(*args)
        result = args - STORAGE_TYPES
        result.empty?
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
          storage[:db] = initialize_db_storage(value, data)
        elsif data.key?(:file)
          value = data[:file]
          storage[:file] = initialize_default_storage(value, :file)
        elsif data.key?(:storage) && data[:storage].is_a?(Array)
          data[:storage].each do |type|
            storage[type] = send("initialize_#{type}_storage", true)
          end
        end
        storage
      end

      def initialize_db_storage(value, opts = {})
        case
        when value == true
          translate_storage_key(:db, domain_name)
        when opts.is_a?(Hash) && opts[:key_translation] == false
          value
        else
          translate_storage_key(:db, value)
        end
      end

      def initialize_file_storage(value, opts = {})
        key = translate_storage_key(:file, domain_name)
        case value
        when true
          {
            model: 'file.model',
            path: "#{storage_path}/#{key.tr('.', '/')}.yml"
          }
        end
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
      # features.membership.{type}.user
      def translate_storage_key(type, partial_key)
        fail "#{type} can not be empty" if partial_key.empty?

        top, *parts = partial_key.split('.')
        top = "features.#{top}" unless top == 'global'
        "#{top}.#{type}.#{parts.join('.')}"
      end

      def assign_storage(type, partial_key)
        @storage[type] = translate_storage_key(partial_key)
      end

      def assign_default_storage(type)
        @storage[type] = "#{type.to_s.underscore}.model"
      end
    end
  end
end
