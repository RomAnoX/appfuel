module Appfuel
  module Domain
    # Domain expressions are used mostly by the criteria to describe filter
    # conditions. The class represents a basic expression like "id = 6", the
    # problem with this expression is that "id" is relative to the domain
    # represented by the criteria. In order to convert that expression to a
    # storage expression for a db, that expression must be fully qualified in
    # the form of "features.feature_name.domain.id = 6" so that the mapper can
    # correctly map to database attributes. This class  provides the necessary
    # interfaces to allow a criteria to qualify all of its relative expressions.
    # It also allows fully qualifed expressions to be used.
    class Expr
      attr_reader :feature, :domain_basename, :domain_attr, :attr_list, :op, :value

      def initialize(domain_attr, op, value)
        @attr_list = parse_domain_attr(domain_attr)
        @op        = op.to_s.strip
        @value     = value

        fail "op can not be empty" if @op.empty?
        fail "attr_list can not be empty" if @attr_list.empty?
      end

      def qualify_feature(feature, domain)
        fail "this expr is already qualified" if qualified?

        attr_list.unshift(domain)
        attr_list.unshift(feature)
        attr_list.unshift('features')
        self
      end

      def qualify_global(domain)
        fail "this expr is already qualified" if qualified?
        attr_list.unshift(domain)
        attr_list.unshift('global')
        self
      end

      def global?
        attr_list[0] == 'global'
      end

      def conjunction?
        false
      end

      def qualified?
        attr_list[0] == 'global' || attr_list[0] == 'features'
      end

      def feature
        index = global? ? 0 : 1
        attr_list[index]
      end

      def domain_basename
        index = global? ? 1 : 2
        attr_list[index]
      end

      def domain_name
        "#{feature}.#{domain_basename}"
      end

      def domain_attr
        start_range = global? ? 2 : 3
        end_range   = -1
        attr_list.slice(start_range .. end_range).join('.')
      end

      def to_s
        "#{attr_list.join('.')} #{op} #{value}"
      end

      def validate_as_fully_qualified
        unless qualified?
          fail "expr (#{to_s}) is not fully qualified, mapping will not work"
        end
        true
      end

      private

      def parse_domain_attr(list)
        list = list.split('.') if list.is_a?(String)

        unless list.is_a?(Array)
          fail "Domain attribute must be a string in the form of " +
               "(foo.bar.id) or an array ['foo', 'bar', 'id']"
        end
        list
      end
    end
  end
end
