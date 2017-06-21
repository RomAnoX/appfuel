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

      attr_reader :config, :uri, :adapter, :content_type

      def initialize
        @config = self.class.load_config
        unless @config.key?(:url)
          fail "[web_api initialize] config is missing :url"
        end
        @uri = URI(@config[:url])
        @adapter = self.class.load_http_adapter
      end

      def url(path)
        uri.to_s + "/#{path}"
      end

      def get(path, options = {})
        add_content_type(options)
        adapter.get(url(path), options)
      end

      def post(path, params = {}, options = {})
        add_content_type(options)
        adapter.post(url(path), params, options)
      end

      private

      def add_content_type(options)
        if content_type && !options.key?(:content_type)
          options[:content_type] = content_type
        end
      end
    end
  end
end
