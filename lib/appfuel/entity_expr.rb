module Appfuel
  class EntityExpr
    OPS = [:eq, :gt, :gteq, :lt, :lteq, :in, :like, :range]
    attr_reader :domain, :attr, :op, :value, :original_attr

    def initialize(attr, data)
      fail "operator value pair must exist in a hash" unless data.is_a?(Hash)
      op, value = data.first
      self.attr   = attr
      self.op     = op
      self.value  = value
    end

    def negated?
      @negated
    end

    def domain?
      !@domain.nil?
    end

    private

    def attr=(value)
      value  = value.to_s
      fail "attribute can not be empty" if value.empty?

      @original_attr  = value
      domain, value  = value.split('.', 2)
      if value.nil?
        value = domain
        domain = nil
      end
      @domain = domain.nil? ? nil : domain.to_s
      @attr   = value.to_s
    end

    def op=(value)
      negated, value = value.to_s.split('_')
      @negated = false
      if negated == 'not'
        @negated = true
      else
        value = negated
      end
      value = value.to_sym
      unless supported_op?(value)
        fail "op has to be one of [#{OPS.join(',')}]"
      end
      @op = value
    end

    def value=(data)
      case op
      when :in
        unless data.is_a?(Array)
          fail ":in operator must have an array as a value"
        end
      when :range
        unless data.is_a?(Range)
          fail ":range operator must have a range as a value"
        end
      when :gt, :gteq, :lt, :lteq
        unless data.is_a?(Numeric)
          fail ":gt, :gteq, :lt, :lteq operators expect a numeric value"
        end
      end
      @value = data
    end

    def supported_op?(op)
      OPS.include?(op)
    end
  end
end
