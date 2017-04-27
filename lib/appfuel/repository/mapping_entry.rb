module Appfuel
  module Repository
    class MappingEntry
      attr_reader :domain_name, :domain_attr, :computed_attr, :persistence_attr,
                  :persistence

      def initialize(data)
        unless data.respond_to?(:to_h)
          fail "Map entry data must respond to :to_h"
        end

        data = data.to_h
        self.domain_name = data.fetch(:domain_name) do
          fail "Fully qualified domain name is required"
        end

        self.persistence = data.fetch(:persistence) do
          fail "Persistence classes hash is required"
        end

        self.persistence_attr = data.fetch(:persistence_attr) do
          fail "Persistence attribute is required"
        end

        self.domain_attr = data.fetch(:domain_attr) do
          fail "Domain attribute is required"
        end

        self.skip = data.fetch(:skip) { false }

        if data.key?(:computed_attr)
          computed_attr_lambda(data[:computed_attr])
        end
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
      def domain_name=(value)
        @domain_name = value.to_s
      end

      def persistence=(value)
        @persistence = value
      end

      def persistence_attr=(value)
        @persistence_attr = value.to_s
      end

      def domain_attr=(value)
        @domain_attr = value.to_s
      end

      def skip=(value)
        @skip = value == true ? true : false
      end

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
