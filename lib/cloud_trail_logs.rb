require 's3'
require 'logging'
# class to deal with cloud trail logs
class CloudTrailLogs < S3
  include Logging

  def initialize(template_config)
     @template_config = template_config
  end

  def fetch_log_data(regions)
    @cloudtrail_logs = []
    regions.each do |region|
      fetch_log_data_of_region(region)
    end
    @cloudtrail_logs
  end

  def fetch_log_data_of_region(region)
    logger.info("fetching log data of region:#{region}")
    cloud_trail_client = get_cloudtrail_client(region)
    is_presence_only = false
    options = { include_shadow_trails: false }
    trails = cloud_trail_client.describe_trails(options)
    cloud_trail_template = File.read(@template_config.cloudtrail_template)
    if trails.trail_list.empty?
      is_logs_enabled = false
      cloud_trail_template_data = ERB.new(cloud_trail_template).result(binding)
      @cloudtrail_logs << @template_config.process_template_data(cloud_trail_template_data)
    else
      trails.trail_list.each do |trail|
        is_logs_enabled = true
        s3 = S3.new
        log_bucket_region = s3.get_bucket_region(trail.s3_bucket_name)
        log_permission = s3.get_bucket_permission(trail.s3_bucket_name)
        cloud_trail_template_data = ERB.new(cloud_trail_template).result(binding)
        @cloudtrail_logs << @template_config.process_template_data(cloud_trail_template_data)
      end
    end
  end

  def fetch_log_presence(regions)
    @cloudtrail_logs = []
    regions.each do |region|
      fetch_log_presence_of_region(region)
    end
    @cloudtrail_logs
  end

  def fetch_log_presence_of_region(region)
    logger.info("fetching log presence of region:#{region}")
    cloud_trail_client = get_cloudtrail_client(region)
    is_presence_only = true
    options = { include_shadow_trails: false }
    trails = cloud_trail_client.describe_trails(options)
    cloud_trail_template = File.read(@template_config.cloudtrail_template)
    if trails.trail_list.empty?
      is_logs_enabled = false
    else
      is_logs_enabled = true
    end
    cloud_trail_template_data = ERB.new(cloud_trail_template).result(binding)
    @cloudtrail_logs << @template_config.process_template_data(cloud_trail_template_data)
  end

  def get_cloudtrail_client(region)
    cloud_trail_client = Aws::CloudTrail::Client.new(region: region)
    cloud_trail_client
  end
end
