Appfuel::Initialize.define('global.http_adapter') do |config, container|
  require 'rest-client'
  container.register('web_api.http_adapter', RestClient)
end
