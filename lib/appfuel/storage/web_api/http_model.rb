require 'uri'

module Appfuel
  module WebApi
    class HttpModel
      include Appfuel::Application::AppContainer
      class << self
        def container_class_type
          'web_api'
        end

        def config_key(value = nil)
          return @config_key if value.nil?
          @config_key = value.to_sym
        end

        def load_config
          config = app_container[:config]
          unless config.key?(config_key)
            fail "[web_api] config key (#{config_key}) not found - #{self}"
          end
          config[config_key]
        end

        def load_http_adapter
          container = app_container
          if container.key?('web_api.http_adapter')
            container['web_api.http_adapter']
          else
            load_default_http_adapter
          end
        end

        def load_default_http_adapter
          unless Kernel.const_defined?(:RestClient)
            require 'rest-client'
          end
          RestClient
        end

        def inherited(klass)
          stage_class_for_registration(klass)
        end
      end

      attr_reader :config, :url, :adapter

      def initialize
        @config = self.class.load_config
        unless @config.key?(:url)
          fail "[web_api initialize] config is missing :url"
        end
        @url = URI(@config[:url])
        @adapter = self.class.load_http_adapter
      end

    end
  end
end
