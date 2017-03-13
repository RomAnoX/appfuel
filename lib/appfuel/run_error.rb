module Appfuel
  class RunError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end
  end
end
