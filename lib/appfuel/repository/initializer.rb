module Appfuel
  module Repository
    class Initializer
      def call(container)
        config = container[:config]
        path = config[:repo_mapping_path]
        unless path
          path = "#{root_path}/config/mappings"
        end
        unless File.exists?(path)
          fail "Failed to load repo maps, file #{path} does not exist"
        end
        require path
      end
    end
  end
end
