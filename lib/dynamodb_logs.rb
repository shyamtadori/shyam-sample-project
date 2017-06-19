require 'logging'
# class to deal with RDS logs
class DynamodbLogs
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def get_dbstream_client(region)
    Aws::DynamoDBStreams::Client.new(region: region)
  end

  def fetch_log_data(regions)
    @dynamodb_logs = []
    regions.each do |region|
      fetch_log_data_of_region(region)
    end
    @dynamodb_logs
  end

  def fetch_log_presence(regions)
    @dynamodb_logs = []
    regions.each do |region|
      fetch_log_presence_of_region(region)
    end
    @dynamodb_logs
  end

  # list_streams returns 100 items by default. To fetch remaining, use last_evaluated_stream_arn
  def fetch_log_data_of_region(region)
    logger.info("fetching log data of region:#{region}")
    dynamodb_template = File.read(@template_config.dynamodb_template)
    is_presence_only = false
    is_streams_present = streams_present?(region)
    dynamodb_template_data = ERB.new(dynamodb_template).result(binding)
    @dynamodb_logs << @template_config.process_template_data(dynamodb_template_data)
  end

  # list_streams returns 100 items by default. To fetch remaining, use last_evaluated_stream_arn
  def fetch_log_presence_of_region(region)
    logger.info("fetching log presence of region:#{region}")
    dynamodb_template = File.read(@template_config.dynamodb_template)
    is_presence_only = true
    is_streams_present = streams_present?(region)
    dynamodb_template_data = ERB.new(dynamodb_template).result(binding)
    @dynamodb_logs << @template_config.process_template_data(dynamodb_template_data)
  end

  def streams_present?(region)
    dbstream_client = get_dbstream_client(region)
    options = { limit: 1 }
    resp = dbstream_client.list_streams(options)
    !resp.streams.empty?
  end

  def fetch_streams(region)
    logger.info("fetching log streams of region:#{region}")
    dbstream_client = get_dbstream_client(region)
    next_token = nil
    streams = []
    loop do
      options = { exclusive_start_stream_arn: next_token }
      resp = dbstream_client.list_streams(options)
      next_token = resp.last_evaluated_stream_arn
      streams += resp.streams
      break unless next_token
    end
    streams
  end

  # Calling from template
  def fetch_stream_data(region)
    log_streams = []
    streams = fetch_streams(region)
    dynamodb_stream_template = File.read(@template_config.dynamodb_stream_template)
 
    streams.each do |stream|
      dynamodb_template_data = ERB.new(dynamodb_stream_template).result(binding)
      log_streams << @template_config.process_template_data(dynamodb_template_data)
    end
    log_streams
  end
end
