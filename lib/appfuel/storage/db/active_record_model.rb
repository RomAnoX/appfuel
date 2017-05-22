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
      include Appfuel::Application::AppContainer

      self.abstract_class = true

      def self.container_class_type
        'db'
      end

      def self.inherited(klass)
        stage_class_for_registration(klass)
      end

      def domain_attrs
        attributes.symbolize_keys.select {|_,value| !value.nil?}
      end
    end
  end
end
