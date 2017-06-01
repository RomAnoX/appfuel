module Appfuel
  module Repository
    # A PEG (Parser Expression Grammer) parser for our domain language. This
    # gives us the ablity to describe the filtering we would like to do when
    # searching on a given domain entity. The search string is parsed and
    # transformed into an interface that repositories can use to determine how
    # to search a given storage interface. The language always represent the
    # business domain entities and not a storage system.
    class ExprParser < Parslet::Parser
      rule(:space) { match('\s').repeat(1) }
      rule(:space?) { space.maybe }

      rule(:comma) { space? >> str(',') >> space? }
      rule(:digit) { match['0-9'] }

      rule(:lparen) { str('(') >> space? }
      rule(:rparen) { str(')') >> space? }

      rule(:integer) do
        (str('-').maybe >> digit >> digit.repeat).as(:integer)
      end

      rule(:float) do
        (
          str('-').maybe >> digit.repeat(1) >> str('.') >> digit.repeat(1)
        ).as(:float)
      end

      rule(:number) { integer | float }

      rule(:boolean) do
        (stri("true") | stri('false')).as(:boolean)
      end

      rule(:string_special) { match['\0\t\n\r"\\\\'] }

      rule(:escaped_special) { str('\\') >> match['0tnr"\\\\'] }

      rule(:string) do
        str('"') >>
        ((escaped_special | string_special.absent? >> any).repeat).as(:string) >>
        str('"')
      end

      rule(:date) do
        (
          digit.repeat(4) >> str('-') >>
          digit.repeat(2) >> str('-') >>
          digit.repeat(2)
        ).as(:date)
      end

      # 1979-05-27T07:32:00Z
      rule(:datetime) do
        (
          digit.repeat(4) >> str('-') >>
          digit.repeat(2) >> str('-') >>
          digit.repeat(2) >> str("T") >>
          digit.repeat(2) >> str(":") >>
          digit.repeat(2) >> str(":") >>
          digit.repeat(2) >> str("Z")
        ).as(:datetime)
      end

      rule(:value) do
        string | number | boolean | datetime | date
      end

      rule(:attr_label) do
        match['a-z0-9_'].repeat(1).as(:attr_label)
      end

      rule(:domain_attr) do
        (attr_label >> (str('.') >> attr_label).repeat).maybe.as(:domain_attr)
      end

      rule(:and_op)     { stri('and')  >> space? }
      rule(:or_op)      { stri('or')   >> space? }
      rule(:in_op)      { (stri('in') | stri('not in'))   >> space? }
      rule(:like_op)    { (stri('like') | stri('not like'))  >> space? }
      rule(:between_op) { (stri('between') | stri('not between')) >> space? }

      rule(:eq_op)      { (str('=') | str('!=')) >> space? }
      rule(:gt_op)      { str('>')    >> space? }
      rule(:gteq_op)    { str('>=')   >> space? }
      rule(:lt_op)      { str('<')    >> space? }
      rule(:lteq_op)    { str('<=')   >> space? }

      rule(:comparison_value) do
        number | date | datetime
      end

      rule(:eq_expr) do
        domain_attr >> space? >> eq_op.as(:op) >> value.as(:value)
      end

      rule(:gt_expr) do
        domain_attr >> space? >>
        gt_op.as(:op) >> space? >>
        comparison_value.as(:value)
      end

      rule(:gteq_expr) do
        domain_attr >> space? >>
        gteq_op.as(:op) >> space? >>
        comparison_value.as(:value)
      end

      rule(:lt_expr) do
        domain_attr >> space? >>
        lt_op.as(:op) >> space? >>
        comparison_value.as(:value)
      end

      rule(:lteq_expr) do
        domain_attr >> space?  >>
        lteq_op.as(:op) >> space? >>
        comparison_value.as(:value)
      end

      rule(:relational_expr) do
        eq_expr | gt_expr | gteq_expr | lt_expr | lteq_expr
      end

      rule(:in_expr) do
        domain_attr >> space >>
        in_op.as(:op) >>
        str('(') >> space? >>
        (value >> (comma >> value).repeat).maybe.as(:value) >> space? >>
        str(')')
      end

      rule(:like_expr) do
        domain_attr >> space >>
        like_op.as(:op) >> space? >>
        string.as(:value)
      end

      rule(:between_expr) do
        domain_attr >> space? >>
        between_op.as(:op) >> space? >>
        (
          comparison_value.as(:lvalue) >> space? >>
          and_op >> space? >>
          comparison_value.as(:rvalue)
        ).as(:value)
      end

      rule(:domain_expr) do
        (
          relational_expr |
          like_expr |
          between_expr |
          in_expr
        ).as(:domain_expr)
      end

      rule(:primary) do
        lparen >> or_operation >> rparen | domain_expr >> space?
      end


      rule(:and_operation) do
        (
          primary.as(:left) >> and_op >> and_operation.as(:right) >> space?
        ).as(:and) | primary
      end

      rule(:or_operation) do
        (
          and_operation.as(:left) >> or_op >> or_operation.as(:right)
        ).as(:or) | and_operation
      end

      # rule for domain
      #
      root(:or_operation)

      def stri(str)
        key_chars = str.split(//)
        key_chars.collect! {|char|
          match["#{char.upcase}#{char.downcase}"]
        }.reduce(:>>)
      end

    end
  end
end
