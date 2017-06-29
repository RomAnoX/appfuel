Appfuel::Initialize.define('global.aws_dynamo_db') do |config, container|
  require 'aws-sdk'
  require 'appfuel/storage/aws_dynamo_db'

  key = Appfuel::AwsDynamoDb::CLIENT_CONTAINER_KEY
  client = Aws::DynamoDB::Client.new

  container.register(key, client)
end
