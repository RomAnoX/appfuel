require 'parslet'
require 'parslet/convenience'

module Appfuel
  module Domain
    # A PEG (Parser Expression Grammer) parser for our domain language. This
    # gives us the ablity to describe the filtering we would like to do when
    # searching on a given domain entity. The search string is parsed and
    # transformed into an interface that repositories can use to determine how
    # to search a given storage interface. The language always represent the
    # business domain entities and not a storage system.
    #
    class ExprParser < Parslet::Parser
      rule(:space) { match('\s').repeat(1) }
      rule(:space?) { space.maybe }

      rule(:comma) { space? >> str(',') >> space? }
      rule(:digit) { match['0-9'] }

      rule(:lparen) { str('(') >> space? }
      rule(:rparen) { str(')') >> space? }

      rule(:number) do
        (
          str('-').maybe >> (
            str('0') | (match['1-9'] >> digit.repeat)
          ) >> (
            str('.') >> digit.repeat(1)
          ).maybe
        ).as(:number)
      end

      rule(:boolean) do
        (stri("true") | stri('false')).as(:boolean)
      end

      rule(:string) do
        str('"') >> (
          str('\\') >> any | str('"').absent? >> any
        ).repeat.as(:string) >> str('"')
      end

      rule(:value) do
        string | number | boolean
      end

      rule(:attr_label) do
        match['a-z0-9_'].repeat(1).as(:attr_label)
      end

      rule(:domain_attr) do
        (
          attr_label.as(:feature) >> str('.') >> attr_label.as(:domain)
        ).as(:domain_attr)
      end

      rule(:domain_object_attr) do
        (
          attr_label >> (str('.') >> attr_label).repeat
        ).as(:domain_object)
      end

      rule(:expr_attr) do
        (
          domain_object_attr | domain_attr | attr_label
        ).as(:expr_attr) >> space?
      end

      rule(:and_op)     { stri('and')  >> space? }
      rule(:or_op)      { stri('or')   >> space? }
      rule(:eq_op)      { str('=')    >> space? }
      rule(:gt_op)      { str('>')    >> space? }
      rule(:gteq_op)    { str('>=')   >> space? }
      rule(:lt_op)      { str('<')    >> space? }
      rule(:lteq_op)    { str('<=')   >> space? }
      rule(:in_op)      { stri('in')   >> space? }
      rule(:like_op)    { stri('like') >> space? }
      rule(:between_op) { stri('between') >> space? }

      rule(:eq_expr) do
        expr_attr >> eq_op.as(:op) >> value
      end

      rule(:gt_expr) do
        expr_attr >> gt_op >> space? >> number
      end

      rule(:gteq_expr) do
        expr_attr >> gteq_op >> space? >> number
      end

      rule(:lt_expr) do
        expr_attr >> lt_op >> space? >> number
      end

      rule(:lteq_expr) do
        expr_attr >> lteq_op >> space? >> number
      end

      rule(:relational_expr) do
        eq_expr | gt_expr | gteq_expr | lt_expr | lteq_expr
      end

      rule(:in_expr) do
        expr_attr >>
        in_op.as(:in_op) >>
        str('(') >> space? >>
        (value >> (comma >> value).repeat).maybe.as(:list) >> space? >>
        str(')')
      end

      rule(:between_expr) do
        expr_attr >> space? >>
        between_op.as(:between_op) >> space? >>
        value.as(:lvalue) >> space? >>
        and_op >> space? >>
        value.as(:rvalue)
      end

      rule(:domain_expr) do
        (relational_expr | between_expr | in_expr) >> space?
      end

      rule(:primary) do
        lparen >> or_operation >> rparen | domain_expr
      end

      rule(:and_operation) do
        (
          primary.as(:left) >> and_op >>
          and_operation.as(:right)
        ).as(:and) | primary
      end

      rule(:or_operation) do
        (
          and_operation.as(:left) >> or_op >>
          or_operation.as(:right)
        ).as(:or) | and_operation
      end

      # foo.id = 6 and last_name = "abc"
      rule(:domain_expr_and) do
        (
          domain_expr >>
          ( and_op >> space? >> domain_expr).repeat.maybe
        ).maybe.as(:domain_expr_and)
      end

      # id = 6 or last_name = "foo"
      rule(:domain_expr_or) do
        (
          domain_expr >>
          ( or_op >> space? >> domain_expr).repeat.maybe
        ).maybe.as(:domain_expr_or)
      end

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
