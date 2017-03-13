module Appfuel
  # This represents the message delivered by RabbitMQ. We encapsulate it
  # so that if you want to fire an action from the command line you can
  # use a CliRequest and not worry about rabbit details
  #
  class CliMsgRequest < MsgRequest

    def initialize (route, input)
      self.inputs       = input
      self.service_route = route
    end

    private
    def inputs=(data)
      fail "input must be a hash" unless data.is_a?(Hash)
      @inputs = data
    end
  end
end
