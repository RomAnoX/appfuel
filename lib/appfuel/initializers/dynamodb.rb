Appfuel::Initialize.define('global.dynamodb') do |config, container|
  require 'aws-sdk'
  require 'appfuel/storage/dynamodb'

  env = config[:env]
  endpoint = config[:aws][:dynamodb][:endpoint]
  region   = config[:aws][:region] || 'us-east-1'
  aws_config = { region: region }

  if ['local', 'development'].include?(env.to_s) && endpoint
    aws_config[:endpoint] = endpoint
  end
  Aws.config.update(aws_config)


  client = Aws::DynamoDB::Client.new
  container.register(Appfuel::Dynamodb::CLIENT_CONTAINER_KEY, client)
end
