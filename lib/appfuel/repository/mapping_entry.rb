module Appfuel
  module Repository
    class MappingEntry
      attr_reader :domain_name, :domain_attr, :computed_attr, :storage_attr,
                  :container_name, :container_key

      def initialize(data)
        unless data.respond_to?(:to_h)
          fail "Map entry data must respond to :to_h"
        end

        data = data.to_h
        @domain_name = data.fetch(:domain_name) {
          fail "Fully qualified domain name is required"
        }.to_s

        @storage = data.fetch(:storage) {
          fail "Storage classes hash is required"
        }

        @storage_attr = data.fetch(:storage_attr) {
          fail "Storage attribute is required"
        }.to_s

        @domain_attr = data.fetch(:domain_attr) {
          fail "Domain attribute is required"
        }

        @skip = data[:skip] == true ? true : false

        if data.key?(:computed_attr)
          computed_attr_lambda(data[:computed_attr])
        end

        @container_name = data[:container]
        @container_key = "mappings.#{domain_name}.#{domain_attr}"
      end

      def storage(type)
        @storage[type]
      end

      def storage?(type)
        @storage.key?(type)
      end

      def skip?
        @skip
      end

      def computed_attr?
        !computed_attr.nil?
      end

      def compute_attr(value, domain)
        fail "No lambda assigned to compute value" unless computed_attr?
        @computed_attr.call(value, domain)
      end

      private
      def computed_attr_lambda(value)
        unless value.lambda?
          fail "computed attributes require a lambda as a value"
        end

        if value.arity != 2
          fail "computed attribute lambda's must accept 2 param"
        end

        @computed_attr = value
      end
    end
  end
end
