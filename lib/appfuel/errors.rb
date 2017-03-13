module Appfuel
  # Feature handler, action handler, command handler all use this class.
  # Presenters and validators will have there errors tranformed into this.
  # Errors are a basic hash structure where each key has an array of strings
  # that represent error messages.
  #
  # Example
  #   messages: {
  #     name: [
  #       'must be present',
  #       'can not be blank',
  #       'can not be Bob'
  #     ]
  #   }
  class Errors
    include Enumerable
    attr_reader :messages

    def initialize(messages = {})
      @messages = messages || {}
      @messages.stringify_keys! unless @messages.empty?
    end

    # Defined to use Enumerable so that we can treat errors
    # as an iterator
    def each
      messages.each do|key, msgs|
        yield key, msgs
      end
    end

    # Add an error message to a given key
    #
    # @param key Symbol   key for this message
    # @param msg String   the message to be stored
    def add(key, msg)
      key = key.to_s
      msg = msg.to_s
      messages[key] = [] unless messages.key?(key)
      messages[key] << msg unless messages[key].include?(msg)
    end

    # Formats the list of messages for each key
    #
    # Example
    #   messages: {
    #     name: [
    #       ' must be present ',
    #       ' can not be blank ',
    #       ' can not be Bob '
    #     ]
    #   }
    #
    # note: spaces are used only for readability
    # name: must be present \n can not be blank \n can not be Bob \n \n
    #
    # @param msg_separator String separates each message default \n
    # @param list_separator String separates each list of messages
    # @return String
    def format(msg_separator = "\n", list_separator = "\n")
      msg = ''
      each do |key, list|
        msg << "#{key}: #{list.join(msg_separator)}#{list_separator}"
      end
      msg
    end

    def delete(key)
      messages.delete(key.to_s)
    end

    def [](key)
      messages[key.to_s]
    end

    def size
      messages.length
    end

    def values
      messages.values
    end

    def keys
      messages.keys
    end

    def clear
      messages.clear
    end

    def empty?
      messages.empty?
    end

    def to_h
      {errors: messages}
    end

    def to_s
      format
    end
  end
end
