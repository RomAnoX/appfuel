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

        def inherited(klass)
          stage_class_for_registration(klass)
        end
      end

      attr_reader :config, :uri, :adapter, :content_type

      def initialize(adapter = RestClient, config = self.class.load_config)
        @config = validate_config(config)
        @uri = create_uri(@config[:url])
        @adapter = adapter
      end

      def url(path)
        if path.start_with?("/")
          path.slice!(0)
        end

        uri.to_s + "#{path}"
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

          handle_method = "handle_#{err.http_code}"

          if respond_to?(handle_method)
            return send(handle_method, err)
          else
            handle_http_error(err.http_code, {}, http_url, err.message)
          end
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
        if content_type == :json && headers[:content_type] == :json
          data = response.body
          return data.empty? ? {} : json(response.body)
        end

        response.body
      end

      def json(data)
        JSON.parse(data)
      end

      private

      def validate_config(data)
        unless data.respond_to?(:to_h)
          fail "[web_api adapter] config must implement :to_h"
        end

        data = data.to_h
        unless data.key?(:url)
          fail "[web_api adapter] config is missing :url"
        end
        data
      end

      def create_uri(api_url)
        unless api_url.end_with?("/")
          api_url = "#{api_url}/"
        end

         URI(api_url)
      end

      def add_content_type(options)
        options[:headers] ||= {}
        if content_type && !options[:headers].key?(:content_type)
          options[:headers][:content_type] = content_type
        end
      end
    end
  end
end
