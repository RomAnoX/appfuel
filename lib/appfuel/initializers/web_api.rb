Appfuel::Initialize.define('global.web_api') do |config, container|
  require 'rest-client'
  container.register('web_api.http_adapter', RestClient)
end
