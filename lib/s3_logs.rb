require 's3'
require 'logging'
# class to deal with s3 logs
class S3Logs < S3
  include Logging

  def initialize(template_config)
    @s3_logs = []
    @template_config = template_config
  end

  def fetch_log_data(required_regions, is_presence_only)
    @is_presence_only = is_presence_only
    buckets = s3_buckets
    required_buckets = filter_required_region_buckets(required_regions, buckets)
    required_buckets.each do |bucket|
      logging_info = logging_info(bucket.name)
      is_logging_enabled = logging_enabled?(logging_info)
      s3_template = File.read(@template_config.s3_template)
      if is_logging_enabled && !@is_presence_only
        log_bucket_name = target_bucket(logging_info)
        prefix = target_prefix(logging_info)
        log_permission = get_bucket_permission(log_bucket_name)
        log_bucket_url = get_bucket_url(log_bucket_name)
      end
      s3_template_data = ERB.new(s3_template).result(binding)
      @s3_logs << @template_config.process_template_data(s3_template_data)
    end
    @s3_logs
  end

  def filter_required_region_buckets(required_regions, buckets)
    required_buckets = []
    buckets.each do |bucket|
      bucket_region = get_bucket_region(bucket.name)
      required_buckets << bucket if required_regions.include? bucket_region
      next
    end
    required_buckets
  end

  def s3_buckets
    logger.info('fetching buckets')
    client = get_s3_client(nil)
    client.list_buckets.buckets
  end

  def logging_info(bucket_name)
    logger.info("fetching log info of #{bucket_name}")
    region = get_bucket_region(bucket_name)
    client = get_s3_client(region)
    options = { bucket: bucket_name, use_accelerate_endpoint: false }
    bucket_logging = client.get_bucket_logging(options)
    (nil if bucket_logging.logging_enabled) || bucket_logging.logging_enabled
  end

  def logging_enabled?(logging_info)
    (true if logging_info) || false
  end

  def target_bucket(logging_info)
    logging_info.target_bucket
  end

  def target_prefix(logging_info)
    logging_info.target_prefix
  end
end
