module Appfuel
  module Dynamodb
    DEFAULT_CONFIG_KEY   = 'aws.dynamodb'
    CLIENT_CONTAINER_KEY = "#{DEFAULT_CONFIG_KEY}.client"

    class NoSqlModel
      include Appfuel::Application::AppContainer

      class << self
        def container_class_type
          'dynamodb'
        end

        def config_key(value = nil)
          if value.nil?
            return @config_key ||= DEFAULT_CONFIG_KEY
          end
          @config_key = value.to_s
        end

        def load_config
          config = app_container[:config]
          key = config_key.to_s
          if key.include?('.')
            keys = key.split('.').map {|k| k.to_sym}
          else
            keys = [config_key]
          end

          @config ||= keys.each.inject(config) do |c, k|
            unless c.key?(k)
              fail "[dynamodb] config key (#{k}) not found - #{self}"
            end
            c[k]
          end
        end

        def config
          @config ||= load_config
        end

        def table_prefix
          @table_prefex ||= config[:table_prefix]
        end

        def client
          @client ||= app_container[CLIENT_CONTAINER_KEY]
        end

        def indexes
          @indexes ||= {}
        end

        def table_name(value = nil)
          return @table_name if value.nil?
          @table_name = "#{table_prefix}#{value}"
        end

        def index(index_key, index_name)
          indexes[index_key.to_sym] = "#{table_prefix}#{index_name}"
        end

        def inherited(klass)
          stage_class_for_registration(klass)
        end

        def primary_key(hash = nil, hash_type = nil, range = nil, range_type = nil)
          return @primary_key if hash.nil?

          @primary_key = PrimaryKey.new(hash, hash_type, range, range_type)
        end
      end

      # Instance methods

      def client
        self.class.client
      end

      def table_name
        self.class.table_name
      end

      def table_prefix
        self.class.table_prefix
      end

      def index_name(key)
        unless self.class.indexes.key?(key)
          fail "index #{key} has not been registered"
        end
        self.class.indexes[key]
      end

      def primary_key
        fail "No primary key assigned" if self.class.primary_key.nil?
        self.class.primary_key
      end


      def put_params(data)
        create_table_hash(item: data)
      end

      def table_params(hash_key_value, range_key_value = nil)
        params = primary_key.params(hash_key_value, range_key_value)
        create_table_hash(key: params)
      end

      def query_select_map(type)
        case type
        when :all_attrs     then 'ALL_ATTRIBUTES'
        when :all_projected then 'ALL_PROJECTED_ATTRIBUTES'
        when :count         then 'COUNT'
        when :specific      then 'SPECIFIC_ATTRIBUTES'
        end
      end

      def select_index_params(key, attrs_returned, key_expr, values = {})
        create_table_hash(
          index_name: index_name(key),
          select:     query_select_map(attrs_returned),
          key_condition_expression: key_expr,
          expression_attribute_values: values
        )
      end

      def select_index(key, select, key_expr, values = {})
        params = select_index_params(key, select, key_expr, values)
        client.query(params)
      end

      def put(data)
        params = put_params(data)
        client.put_item(params)
      end

      def get(hash_value, range_value = nil)
        result = get_item(hash_value, range_value)
        return false if result.item.nil?

        result.item
      end

      def get_item(hash_value, range_value = nil)
        params = table_params(hash_value, range_value)
        client.get_item(params)
      end

      def delete(hash_value, range_value = nil)
        delete_item(hash_value, range_value)
      end

      def delete_item(hash_value, range_value = nil)
        params = table_params(hash_value, range_value)
        client.delete_item(params)
      end

      private
      def create_table_hash(data = {})
        data.merge!(table_name: table_name)
      end
    end
  end
end
