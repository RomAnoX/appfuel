require 'uri'
require 'json'
require 'rest-client'

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

      def request(method, path, options = {})
        add_content_type(options)
        http_url = url(path)
        if options[:relative_url] === false
          http_url = path
          options.delete(:relative_url)
        end

        begin
          data = options.merge({method: method, url: http_url })
          response = adapter::Request.execute(data)
          response = handle_response(response, options[:headers])
        rescue RestClient::ExceptionWithResponse => err
          data = handle_response(err.response, options[:headers])
          handle_http_error(err.http_code, data, http_url, err.message)
        end

        response
      end


      def handle_http_error(code, body, url, msg)
        if body.is_a?(Hash)
          body = body.map{|k,v| "#{k}: #{v}"}.join('&')
        end
        str = "[#{url} #{code}] #{msg} #{body}"
        raise str
      end

      def handle_response(response, headers = {})
        if content_type == :json || headers[:content_type] == :json
          return json(response.body)
        end

        response.body
      end

      def json(data)
        JSON.parse(data)
      end

      private

      def add_content_type(options)
        options[:headers] ||= {}
        if content_type && !options[:headers].key?(:content_type)
          options[:headers][:content_type] = content_type
        end
      end
    end
  end
end
