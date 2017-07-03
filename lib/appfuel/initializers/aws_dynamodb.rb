Appfuel::Initialize.define('global.aws_dynamodb') do |config, container|
  require 'aws-sdk'
  require 'appfuel/storage/aws_dynamodb'

  env = config[:env]
  if ['local', 'development'].include?(env.to_s)
    Aws.config.update({
      region: config[:aws][:dynamodb][:region],
      endpoint: config[:aws][:dynamodb][:endpoint]
    })
  end
  key = Appfuel::AwsDynamodb::CLIENT_CONTAINER_KEY

  client = Aws::DynamoDB::Client.new

  container.register(key, client)
end
