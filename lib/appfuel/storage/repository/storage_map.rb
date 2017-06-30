module Appfuel
  module Repository
    class StorageMap
      attr_reader :domain_name, :container_name, :entries,
                  :storage_type, :storage_key

      def initialize(data)
        fail "Mapping data must be a hash" unless data.is_a?(Hash)

        @container_name = data[:container]
        @domain_name    = data.fetch(:domain_name)  { domain_name_failure }.to_s
        @storage_type   = data.fetch(:storage_type) { storage_type_failure }
        @storage_key    = data.fetch(:storage_key)  { storage_key_failure }
        @entries        = data.fetch(:entries)      { entries_failure }
      end

      def storage_attr(domain_attr)
        entries.each do |data|
           return data[:storage_attr] if data[:domain_attr] == domain_attr
        end

        fail "[storage_map #{domain_name}] #{domain_attr} not registered"
      end

      def domain_attr(storage_attr)
        entries.each do |data|
           return data[:domain_attr] if data[:storage_attr] == storage_attr
        end

        fail "[storage_map #{domain_name}] #{storage_attr} not registered"
      end

      def each
        entries.each do |data|
          yield data[:domain_attr], data[:storage_attr], data[:skip]
        end
      end

      private

      def domain_name_failure
        fail "Fully qualified domain name is required"
      end

      def storage_type_failure
        domain_failure("storage_type is required for storage map")
      end

      def storage_key_failure
        domain_failure(":storage_key is required for storage map")
      end

      def entries_failure
        domain_failure(":mapping_entries are required for storage map")
      end

      def domain_failure(msg)
        fail "[#{domain_name}] #{msg}"
      end
    end
  end
end
