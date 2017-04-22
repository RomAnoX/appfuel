module Appfuel
  module Handler
    module InjectDsl
      TYPES = [:domain, :cmd, :repo, :container]

      def injections
        @injections ||= {
          domain: {},
          repositories: {},
          commands: {},
          container: {}
        }
      end

      def inject(type, key, opts = {})
        if type == :domain
          return injections[:domain][key] = opts[:as]
        end

        cat = case type
              when :repo then 'repositories'
              when :cmd  then 'commands'
              else
                "container"
              end

        namespaced_key = parse_key(key, cat)
        injections[cat.to_sym][namespaced_key] = opts[:as]
      end

      private

      def parse_key(key, type_key = nil)
        parts     = key.to_s.split('.')
        namespace = feature_key
        if parts[0].downcase == 'global'
          namespace = 'global'
          parts.shift
        end
        path = parts.join('.')

        if type_key == "contianer"
          type_key = ''
        else
          type_key = "#{type_key}."
        end

        "#{namespace}.#{type_key}#{path}"
      end

      def inject_type?(type)
        TYPES.include(type)
      end
    end
  end
end
