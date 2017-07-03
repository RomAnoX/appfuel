module Appfuel
  module AwsDynamodb
    CLIENT_CONTAINER_KEY = 'aws.dynamodb.client'
    class NoSqlModel
      include Appfuel::Application::AppContainer

      class << self
        def container_class_type
          'aws.dynamo_db'
        end

        def config_key(value = nil)
          return @config_key if value.nil?
          @config_key = value.to_sym
        end

        def load_config
          config = app_container[:config]
          unless config.key?(config_key)
            fail "[aws_dynamodb] config key (#{config_key}) not found - #{self}"
          end
          config[config_key]
        end

        def load_client
          app_container[CLIENT_CONTAINER_KEY]
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
