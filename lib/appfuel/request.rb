module Appfuel
  class Request
    attr_reader :action_route, :feature, :action, :inputs, :namespace

    def initialize(action_route, inputs = {})
      unless inputs.respond_to?(:to_h)
        fail "inputs must respond to :to_h"
      end
      @inputs = inputs.to_h
      @action_route, @feature, @action = parse_route(action_route)
      @namespace = "features.#{feature}.actions.#{action}"
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
      feature_name, action_name = route.to_s.split('/')

      feature_name = handle_parsed_string(feature_name)
      action_name  = handle_parsed_string(action_name)

      handle_empty_feature(feature_name)
      handle_empty_action(action_name)


      [route, feature_name.underscore, action_name.underscore]
    end

    def handle_parsed_string(value)
      value.to_s.strip
    end

    def handle_empty_feature(feature_name)
      return unless feature_name.empty?
      fail "feature is missing, action route must be like <feature/action>"
    end

    def handle_empty_action(action_name)
      return unless action_name.empty?
      fail "action is missing, action route must be like <feature/action>"
    end
  end
end
