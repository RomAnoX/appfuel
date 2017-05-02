module Appfuel
  module Domain

    module DomainNameParser

      # This parse the domain name string or object with domain_name method
      # and returns an array with feature, domain and name.
      # @example
      #   parse_domain_name('Foo.Bar.Baz')
      #   ['Foo', 'Bar', 'Foo.Bar.Baz']
      # @param name [String, Object] domain name
      # @return [Array] parsed Array from domain name
      def parse_domain_name(name)
        if !name.is_a?(String) && !name.respond_to?(:domain_name)
          fail 'domain name must be a string or implement method :domain_name'
        end

        name = name.domain_name if name.respond_to?(:domain_name)
        feature, domain = name.split('.')
        if domain.nil?
          domain, feature  = feature, nil
        end

        [feature, domain, name]
      end

      # This parse the domain attributes string and returns an array with
      # two elements.
      # @example
      #   parse_domain_attr('Foo.Bar.Baz')
      #   ['Foo.Bar', 'Baz']
      # @param name [String] domain name attributes
      # @return [Array] parsed Array from domain attributes
      def parse_domain_attr(name)
        unless name.is_a?(String)
          fail 'domain attribute name must be a string'
        end

        *first, last = name.split('.')
        [first.join('.'), last]
      end
    end
  end
end
