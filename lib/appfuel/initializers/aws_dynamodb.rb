Appfuel::Initialize.define('global.aws_dynamodb') do |config, container|
  require 'aws-sdk'
  require 'appfuel/storage/aws_dynamodb'

  env = config[:env]
  endpoint = config[:aws][:dynamodb][:endpoint]
  if ['local', 'development'].include?(env.to_s) && endpoint
    Aws.config.update({
      endpoint: endpoint
    })
  end
  key = Appfuel::AwsDynamodb::CLIENT_CONTAINER_KEY

  client = Aws::DynamoDB::Client.new

  container.register(key, client)
end
