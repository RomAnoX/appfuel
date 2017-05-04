module Appfuel
  module Repository
    class Initializer
      def call(container)
        config    = container[:config]
        root_path = container[:root_path]
        path      = config[:repo_mapping_path]
        unless path
          path = "#{root_path}/storage/mappings"
        end

        unless ::File.exist?(path)
          fail "Failed to load repo maps, file #{path} does not exist"
        end
        require path
      end
    end
  end
end
