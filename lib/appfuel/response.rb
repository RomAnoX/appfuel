module Appfuel
  # Every action or command must return a response. A response is either
  # ok or it has errors. You can retrieve the results with the "ok" method
  # or the errors with the "error" method
  class Response

    class << self
      # Convience method for creating a successfull response
      #
      # @param  result Hash the successfull resultset
      # @reuturn Response
      def ok(result = nil)
        result = ok_data(result) if ok_key?(result)
        self.new(ok: result)
      end

      def ok_key?(data)
        data.key?(:ok) || data.key?("ok")
      end

      def error_key?(data)
        data.key?(:errors) || data.key?("errors")
      end

      def ok_data(data)
        data[:ok] || data['ok']
      end

      def error_data(data)
        data[:errors] || data['errors']
      end

      # Convience method for creating an error response. It understands
      # how to handle a SpCore::Error object. Any thing that
      # is not a hash or can't be converted to a hash is assumed to be
      # a string and converted into a general_error
      #
      # @param data Hash the errors hash
      # @reuturn Response
      def error(data)
        result = format_result_hash(data, default_key: :general_error)
        result = result[:errors] if result.key?(:errors)
        self.new(errors: result)
      end

      def format_result_hash(data, default_key:)
        if data.is_a?(Hash)
          result = data
        elsif data.respond_to?(:to_h)
          result = data.to_h
        else
          result = {default_key => data.to_s}
        end

        result.symbolize_keys
      end
    end

    attr_reader :ok, :errors

    # @param data [Hash]
    # @return [Response]
    def initialize(data = {})
      result = format_result_hash(data)

      # when no ok key and no errors key then assume
      # it is a successfull response
      if !self.class.ok_key?(result) && !self.class.error_key?(result)
        result = {ok: self.class.ok_data(result)}
      end

      @ok = result[:ok]
      @errors = nil
      if self.class.error_key?(result)
        @ok = nil
        @errors = Errors.new(self.class.error_data(result))
      end
    end

    def errors?
      !ok?
    end
    alias_method :failure?, :errors?

    def error_messages
      return {} if ok?

      errors.messages
    end

    def ok?
      errors.nil?
    end
    alias_method :success?, :ok?

    def to_h
      if ok?
        {ok: ok}
      else
        errors.to_h
      end
    end

    def to_json
      to_h.to_json
    end

    private
    def format_result_hash(data)
      self.class.format_result_hash(data, default_key: :ok)
    end
  end
end
