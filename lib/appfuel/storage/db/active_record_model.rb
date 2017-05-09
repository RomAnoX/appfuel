module Appfuel
  module Db
    class ActiveRecordModel < ActiveRecord::Base
      # ChangeOrder::Global::Db::FooBar
      #
      # ChangeOrder::Membership::Peristence::Db::Account
      # ChangeOrder::Membership::Persistence::Yaml::Account
      #
      # ChangeOrder::Membership::Domains::Account
      #
      # Appfuel.mapping membership.account,
      #                 db: account, yaml: account do
      #   map id, account.id
      # end
      #
      # module Membership
      #   module Db
      #
      #   end
      # end
      #
      #
      # global.db.foobar
      #
      # features.membership.db.account
      # features.membership.yaml.account
      #
      #
      self.abstract_class = true
      include Appfuel::Application::AppContainer
      def self.inherited(klass)
        super
        register_container_class(klass)
      end


      def entity_attributes
        attributes.symbolize_keys.select {|_,value| !value.nil?}
      end
    end
  end
end
