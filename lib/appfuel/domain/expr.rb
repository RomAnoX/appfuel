module Appfuel
  module Domain
    # Domain expressions are used mostly by the criteria to describe filter
    # conditions. The class represents a basic expression like "id eq 6", the
    # problem with this expression is that we need additional information in
    # order to properly map it to something like a db expression. This call
    # ensures that additional information exists. Most importantly we need
    # a fully qualified domain name in the form of "feature.domain".
    class Expr
      attr_reader :feature, :domain_basename, :domain_attr, :attr_list, :op, :value

      def initialize(attr_list, op, value)
        @attr_list = attr_list
        @op        = op.to_s.strip
        @value     = value

        fail "op can not be empty" if @op.empty?
        fail "attr_list can not be empty" if @attr_list.empty?
      end

      # id -> attr_only this is the top of the domain -> feature unkown, domain unknown
      # foo.id ->  attr in an object at the top of the domain - domain unknown
      # foo.bar.baz.id -> long object chain same as above -> domain unknow
      # features.foo.id -> qualified feature.domain ->
      # global.user.id  -> qualified global domain  ->
      #
      # attr_list qualified domain with a top level attribute
      #   0: global || features
      #   1: membership (name of feature)
      #   2: user (basename of domain)
      #   3: id attr of domain
      #
      # attr_list qualified domain of a domain with an simple object with an attr
      #   0: global || features
      #   1: membership (name of feature)
      #   2: user (basename of domain)
      #   3: role object mapped to domain
      #   4: id attr of role mapped to user (role.id
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

      # global.user.id
      # features.memberships.user.id
      # features.membershipes.user.role.id
      #
      # id
      # role.id
      #
      #
      #
      #
      #
      def domain_attr
        start_range = global? ? 2 : 3
        end_range   = -1
        attr_list.slice(start_range .. end_range).join('.')
      end

      def expr_string
        data = yield domain_attr, op
        lvalue   = data[0]
        operator = data[1]
        rvalue   = data[2]

        operator = "NOT #{operator}" if negated?
        "#{lvalue} #{operator} #{rvalue}"
      end

      def to_s

        "#{attr_list.join('.')} #{op} #{value}"
      end

      def validate_as_fully_qualified
        unless qualified?
          fail "domain_name requires a fully qualified domain (#{self.to_s})"
        end
      end
    end
  end
end
