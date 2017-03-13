module Appfuel
  class Request
    attr_reader :action_route, :feature, :action, :inputs

    def initialize(action_route, inputs)
      unless inputs.respond_to?(:to_h)
        fail "inputs must respond to :to_h"
      end
      @inputs = inputs.to_h
      @action_route, @feature, @action = parse_route(action_route)
    end

    private

    # The service route is a forward slash separated string consisting of two
    # parts. The first part is the feature that holds the action and the
    # second is the action itself.
    #
    # @example 'offers/create'
    #   feature is Offers
    #   action is Create
    #
    # @param route [String]
    # @return [Array]
    def parse_route(route)
      feature, action = route.to_s.split('/')

      # NOTE: feature.strip! returns nil we are really after the empty?
      if feature.nil? || (feature.strip! || feature.empty?)
        fail "feature is missing, action route must be like <feature/action>"
      end

      if action.nil? || (action.strip! || action.empty?)
        fail "action is missing, action route must be like <feature/action>"
      end

      [route, feature.classify, action.classify]
    end
  end
end
