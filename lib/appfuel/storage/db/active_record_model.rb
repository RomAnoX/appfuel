module Appfuel
  module Db
    # ActiveRecord::Base that auto registers itself into the application
    # container and symbolizes its attributes. This is used by the db
    # mapper to persist and retreive domains to and from the database.
    #
    # NOTE: we are coupling ourselves to active record right now. I have
    #       plans to resolve this but right now its a lower priority. You
    #       can get around this by implementing your own mapper, and db model.
    #
    class ActiveRecordModel < ActiveRecord::Base
      include Appfuel::Application::AppContainer

      self.abstract_class = true

      # Contributes to the construction of a fully qualified container key
      #
      # @example
      #   global model:  global.db.user
      #   feature model: features.membership.db.user
      #
      # @return [String]
      def self.container_class_type
        'db'
      end

      # Registers the class inside the application container. The class
      # being registered as the mixin required for registration.
      #
      # @params klass [Class] class that is inheriting this one
      # @return results from super
      def self.inherited(klass)
        stage_class_for_registration(klass)
        super
      end

      # Symbolize active record attributes and remove attributes with
      # nil values
      #
      # @return [Hash]
      def domain_attrs
        attributes.symbolize_keys.select {|_k, v| !v.nil? }
      end
    end
  end
end
