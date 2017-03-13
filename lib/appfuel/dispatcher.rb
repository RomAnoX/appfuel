module Appfuel
  # When a message is pulled out of a queue by the queue handler it
  # will contain a service_route in the form "feature/action". Features
  # are a module namespace to hold actions. The dispatcher uses
  # this to find the feature and use that to find the action. It then
  # delegates the request inputs to the action's run method
  module Dispatcher

    # @param  request Request request object used to call the action
    # @param  root Module   root module of the feature
    # @return Response   the response object from the action
    def dispatch(route, inputs = {}, root: nil)
      request = if route.kind_of?(Request)
                  route
                else
                  Request.new(route, inputs)
                end

      dispatch_request(request, root)
    end

    # @param  request Request request object used to call the action
    # @param  root Module   root module of the feature
    # @return Response   the response object from the action
    def dispatch_request(request, root = nil)
      root ||= root_module
      fail "Root module must be a Module" unless root.is_a?(Module)

      unless root.const_defined?(request.feature)
        fail "Feature (#{request.feature}) not found in #{root}"
      end

      feature = root.const_get(request.feature)
      unless feature.const_defined?(request.action)
        fail "Action (#{request.action}) not found in #{feature}"
      end

      action_class = feature.const_get(request.action)
      action_class.run(request.inputs)
    end
  end
end
