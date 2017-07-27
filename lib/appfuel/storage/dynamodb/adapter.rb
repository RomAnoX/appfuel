module Appfuel
  module Dynamodb
    CLIENT_CONTAINER_KEY = 'aws.dynamodb.client'

    class NoSqlModel
      include Appfuel::Application::AppContainer

      class << self
        def container_class_type
          'dynamodb'
        end

        def config_key(value = nil)
          return @config_key if value.nil?
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

        def primary_key(hash_key, hash_type, range_key = nil, range_type = nil)
          @primary_key = [ {hash_key => hash_type.to_s.downcase} ]
          unless range_key.nil?
            fail "range type is required" if range_type.nil?
            @primary_key << { range_key => range_type }
          end
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

      def put_params(data)
        {
          table_name: table_name,
          item: data
        }
      end

      def table_params(keys ={})
        {
          table_name: table_name,
          key: keys
        }
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
        {
          table_name: table_name,
          index_name: index_name(key),
          select:      query_select_map(attrs_returned),
          key_condition_expression: key_expr,
          expression_attribute_values: values
        }
      end

      def select_index(key, select, key_expr, values = {})
        params = select_index_params(key, select, key_expr, values)
        client.query(params)
      end

      def index_query_params(key, opts = {})
        if opts.key?(:select)
          params[:select] = query_select_map(opts[:select])
        end

      end
    end
  end
end
