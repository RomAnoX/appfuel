Appfuel::Initialize.define('global.db') do |config, container|
  fail "[initializer db] :db config not found" unless config.key?(:db)
  fail "[initializer db] :main not found in :db" unless config[:db].key?(:main)

  require 'pg'
  require 'active_record'
  config[:db][:main] = config[:db][:main].with_indifferent_access

  ActiveSupport.on_load(:active_record) do
    if ActiveRecord::Base.connected?
      ActiveRecord::Base.connection_pool.disconnect!
    end

    if container.key?(:logger)
      ActiveRecord::Base.logger = container[:logger]
    end

    ActiveRecord::Base.establish_connection(config[:db][:main])
  end
  nil
end
