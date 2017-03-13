module Appfuel
  class ResponseHandler
    attr_reader :response_class

    def initialize(response_class = Response)
      @response_class = response_class
    end

    def create_response(data)
      return data        if response?(data)
      return error(data) if error_data?(data)
      ok(data)
    end

    def response?(data)
      data.is_a?(response_class)
    end

    # Determine if the data given is an error by looking at its class or
    # checking if it is a hash with the key :errors
    #
    # @param data
    # @return Bool
    def error_data?(data)
      case
      when data.kind_of?(::StandardError) || data.is_a?(Errors)
        true
      when data.is_a?(Hash)
        data.key?(:errors)
      else
        false
      end
    end

    # This is used when returning results back to the action handler. We
    # use this to indicate it was a successful response
    #
    # @param ok Hash
    # @return Response
    def ok(value = nil)
      response_class.ok(value)
    end

    # Convert a number of different error formats into hash and use that to
    # build the response
    #
    # @param args StandardError|ActiveModel::Errors|Hash|Errors|Symbol|Response
    # @return Response
    def error(*args)
      error = args.shift
      case
      when error.kind_of?(ActiveModel::Errors)
        messages = error.messages
      when error.kind_of?(StandardError)
        key = error.class.to_s.underscore.to_sym
        backtrace_key = "#{key}_backtrace".to_sym
        messages = {
          errors: {
            key => [error.message],
            backtrace_key => error.backtrace || []
          }
        }
      when error.is_a?(Hash)
        messages = error.key?(:errors) ? error : {errors: error}
      when error.is_a?(Errors)
        messages = error.to_h

      when args.length >= 1
        messages = {errors: {error => args}}
      when error.is_a?(response_class)
        return error
      else
        messages = {errors: {general_error: [error.to_s]}}
      end

      response_class.error(messages)
    end
  end
end
