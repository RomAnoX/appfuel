module Appfuel
  class EntityExpr
    OPS = [:eq, :gt, :gteq, :lt, :lteq, :in, :like, :range]
    attr_reader :entity, :attr, :op, :value

    def initialize(entity, attr, data)
      fail "operator value pair must exist in a hash" unless data.is_a?(Hash)
      op, value  = data.first
      @entity    = entity.to_s
      @attr      = attr.to_s
      self.op    = op
      self.value = value

      fail "entity name can not be empty" if @entity.empty?
      fail "attribute can not be empty" if @attr.empty?
    end

    def negated?
      @negated
    end

    private

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
