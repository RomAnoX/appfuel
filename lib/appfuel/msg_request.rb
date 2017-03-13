module Appfuel
  # This represents the message delivered by RabbitMQ. We encapsulate it
  # so that if you want to fire an action from the command line you can
  # use a CliRequest and not worry about rabbit details
  #
  class MsgRequest
    attr_reader :config, :service_route, :reply_to, :correlation_id,
      :delivery_info, :properties, :feature, :action, :inputs, :current_user

    #
    # metadata properties
    #   headers:        message headers, important for service_route
    #   reply_to:       name of rpc response queue
    #   correlation_id: id used in rpc to match response
    #
    # @param msg            String  serialized message from rabbitmq
    # @param delivery_info  Hash    info used to acknowledge messages
    # @param metadata       Object  properties of the messages
    #
    # @return MsgRequest
    def initialize(msg, delivery_info, metadata)
      @auditable         =  true
      self.inputs        = msg
      self.delivery_info = delivery_info
      self.properties    = metadata
    end

    # Rpc requires a reply queue to respond to and a correlation_id to
    # identify that response in the queue. When these two things exist
    # then the request is consided to be an rpc
    #
    # @return [Boolean]
    def rpc?
      !reply_to.nil? && !correlation_id.nil?
    end

    # Flag used to determine if the request should be sent to the audit log.
    # The default value is true and a header is used to opt out of this.
    #
    # @return [Boolean]
    def auditable?
      @auditable
    end

    # The current user is required for all audit logs and this flag is used
    # to determine if it exists. When an audit is not required the current
    # user is optional
    #
    # @return [Boolean]
    def current_user?
      !@current_user.nil?
    end

    private

    # Ensures when a current_user_id is given it is valid. This is optional
    # and the msg will not enforce its presence when auditable is true, that
    # will be handled by objects implementing auditing.
    #
    # @param value [Integer, nil] the current user id
    # @return [Integer, nil]
    def current_user=(value)
      return @current_user = nil if value.nil?

      begin
        @current_user = Integer(value)
      rescue
        raise 'current_user_id must be an Integer'
      end
    end

    # All message inputs are sent encoded as json. We parse then json then
    # symbolize the keys which allows any validation, action or command to
    # expect a consistent hash
    #
    # @param data [String]
    # @return [Hash]
    def inputs=(data)
      data = data.to_s
      return @inputs = {} if data.empty?


      begin
        data = JSON.parse(data)
        fail "message inputs must be a hash" unless data.is_a?(Hash)
        @inputs = data.deep_symbolize_keys
      rescue => e
        msg = "message request could not parse the inputs: #{e.message}"
        error = RuntimeError.new(msg)
        error.set_backtrace(e.backtrace)
        raise error
      end
    end

    # Hash like structure that hold information about the delivery of the message
    #   :consumer_tag   Each consumer (subscription) has an identifier called a
    #                   consumer tag. It can be used to unsubscribe from
    #                   messages. Consumer tags are just strings.
    #
    #   :delivery_tag   If set to 1, the delivery tag is treated as
    #                   "up to and including", so that multiple messages can be
    #                   acknowledged with a single method. If set to zero, the
    #                   delivery tag refers to a single message. If the multiple
    #                   field is 1, and the delivery tag is zero, this indicates
    #                   acknowledgement of all outstanding messages.
    #
    #   :redelivered    true if this delivery is a redelivery ( the message was
    #                   requeued at least once )
    #
    #   :routing_key    routing key used by exchange to route to queue
    #
    #   :exchange       name of exchange
    #
    #   :consumer       the consumer that subsribed
    #
    #   :channel        the channel the message was sent on
    #
    # @param data [Bunny::Delivery::Info]
    # @return [Bunny::Delivery::Info]
    def delivery_info=(data)
      @deliver_info = data
    end

    # Hash like structure that holds attributes of the message as defined by
    # the amqp protocol
    #
    #   :content_type       (Optional) content type of the message, as set by
    #                       the publisher
    #
    #   :content_encoding   (Optional) content encoding of the message, as set
    #                       by the publisher
    #
    #   :headers            message headers
    #
    #   :delivery_mode      [Integer] Delivery mode (persistent or transient)
    #
    #   :priority           [Integer] Message priority, as set by the publisher
    #
    #   :correlation_id     [String] What message this message is a reply to
    #                       (or corresponds to), as set by the publisher
    #
    #   :reply_to           [String] (Optional) How to reply to the publisher
    #                       (usually a reply queue name)
    #
    #   :expiration         [String] Message expiration, as set by the publisher
    #
    #   :message_id         [String] Message ID, as set by the publisher
    #
    #   :timestamp          [Time] Message timestamp, as set by the publisher
    #
    #   :user_id            [String] Publishing user, as set by the publisher
    #                       not an application user
    #
    #   :app_id             [String] Publishing application, as set by the
    #                       publisher
    #
    #   :cluster_id         [String] Cluster ID, as set by the publisher
    #
    # @param data [Bunny::MessageProperties]
    # @return Bunny::MessageProperties
    def properties=(data)
      @reply_to        = data.reply_to
      @correlation_id  = data.correlation_id

      if data.headers['auditable'] == false
        @auditable = false
      end

      self.service_route = data.headers['service_route']
      self.current_user  = data.headers['current_user']
      @properties = data
    end

    # The service route is a forward slash separated string consisting of two
    # parts. The first part is the feature that holds the action and the
    # second is the action itself.
    #
    # @example 'offers/create'
    #   feature is Offers
    #   action is Create
    #
    # This is used by the dispatcher to locate the action to be called
    #
    # @param route [String]
    # @param [String]
    def service_route=(route)
      fail "service route missing from message headers" if route.nil?
      fail "service route must be a String" unless route.is_a?(String)

      feature, action= route.split('/', 2)

      # NOTE: feature.strip! returns nil we are really after the empty?
      if feature.nil? || (feature.strip! || feature.empty?)
        fail "feature is missing route must be like <feature>/<action>"
      end

      if action.nil? || (action.strip! || action.empty?)
        fail "action is missing route must be like <feature>/<action>"
      end

      @service_route = route
      @feature = feature.camelize
      @action  = action.camelize
      route
    end
  end
end
