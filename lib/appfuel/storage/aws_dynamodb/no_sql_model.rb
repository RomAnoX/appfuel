module Appfuel
  module AwsDynamodb
    CLIENT_CONTAINER_KEY = 'aws.dynamodb.client'
    class NoSqlModel
      include Appfuel::Application::AppContainer

      class << self
        def container_class_type
          'aws.dynamodb'
        end

        def config_key(value = nil)
          return @config_key if value.nil?
          @config_key = value.to_sym
        end

        def load_config
          config = app_container[:config]
          key = config_key.to_s
          if key.contains?('.')
            keys = config_key.split('.').map {|k| k.to_sym}
          else
            keys = [config_key]
          end

          keys.each.inject(config) do |c, k|
            unless c.key?(k)
              fail "[aws_dynamodb] config key (#{k}) not found - #{self}"
            end
            c[k]
          end
        end

        def load_client
          app_container[CLIENT_CONTAINER_KEY]
        end

        def table_name(value = nil)
          return @table_name if value.nil?

          prefix = load_config[:table_prefix]
          @table_name = "#{prefix}#{value}"
        end

        def inherited(klass)
          stage_class_for_registration(klass)
        end
      end

      attr_reader :config, :client

      def initialize
        @client = self.class.load_client
        @config = self.class.load_config
        @table_prefix = @config.fetch(:table_prefix) { '' }
      end

    end
  end
end
