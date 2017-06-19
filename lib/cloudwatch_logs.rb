require 'logging'
# class to deal with cloudwatch logs
class CloudWatchLogs
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def get_cloud_watch_client(region)
    Aws::CloudWatchLogs::Client.new(region: region)
  end

  def fetch_log_data(regions, presence_only)
    @presence_only = presence_only
    @cloud_watch_logs = []
    regions.each do |region|
      fetch_log_data_of_region(region)
    end
    @cloud_watch_logs
  end

  def fetch_log_data_of_region(region)
    logger.info("fetching log data of region:#{region}")
    cloud_watch_client = get_cloud_watch_client(region)
    log_groups = fetch_log_groups(cloud_watch_client)

    cloudwatch_group_template = File.read(@template_config.cloudwatch_group_template)
    log_groups.each do |log_group|
      group_log_data = ERB.new(cloudwatch_group_template).result(binding)
      @cloud_watch_logs << @template_config.process_template_data(group_log_data)
    end
    @cloud_watch_logs
  end

  # describe_log_streams returns 50 items by default. To fetch remaining, use next_token (Note : calling it from template)
  def fetch_log_streams(client, log_group)
    logger.info("fetching log streams of group:#{log_group.log_group_name}")
    streams = []
    log_streams = []
    next_token = nil

    begin
      options = { log_group_name: log_group.log_group_name, next_token: next_token }
      resp = client.describe_log_streams(options)
      log_streams += resp.log_streams
      next_token = resp.next_token
    end while next_token

    cloudwatch_stream_template = File.read(@template_config.cloudwatch_stream_template)
    log_streams.each do |log_stream|
      stream_template_date = ERB.new(cloudwatch_stream_template).result(binding)
      streams << @template_config.process_template_data(stream_template_date)
    end
    streams
  end

  # describe_log_groups returns 50 items by default. To fetch remaining, use next_token
  def fetch_log_groups(client)
    logger.info('fetching log groups')
    log_groups = []
    next_token = nil

    begin
      options = { next_token: next_token }
      resp = client.describe_log_groups(options)
      log_groups += resp.log_groups
      next_token = resp.next_token
    end while next_token
    log_groups
  end
end
