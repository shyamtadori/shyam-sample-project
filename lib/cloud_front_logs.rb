require 's3'
require 'logging'
# class to deal with cloud front logs
class CloudFrontLogs < S3
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def fetch_log_data
    @is_presence_only = false
    fetch_distribution_logs
  end

  def fetch_log_presence
    @is_presence_only = true
    fetch_distribution_logs
  end

  def fetch_distribution_logs
    @cloudfront_logs = []
    cloudfront_client = get_cloudfront_client

    distributions = get_destributions(cloudfront_client)
    distributions.each do |distribution|
      destribution_details = get_distribution_details(cloudfront_client, distribution.id)
      @cloudfront_logs << destribution_details if destribution_details
    end
    @cloudfront_logs
  end

  def get_cloudfront_client
    cloudfront_client = Aws::CloudFront::Client.new
    cloudfront_client
  end

  def get_destributions(client)
    logger.info('fetching destributions')
    next_token = nil
    distributions = []
    loop do
      options = { marker: next_token }
      resp = client.list_distributions(options)
      distributions += resp.distribution_list.items
      next_token = resp.distribution_list.next_marker
      break unless next_token && !next_token.empty?
    end
    distributions
  end

  def get_distribution_details(client, distribution_id)
    logger.info("fetching details about distribution:#{distribution_id}")
    options = { id: distribution_id }
    resp = client.get_distribution(options)

    is_logging_enabled = resp.distribution.distribution_config.logging.enabled
    if is_logging_enabled && !@is_presence_only
      log_bucket = resp.distribution.distribution_config.logging.bucket
      log_bucket_name = log_bucket.split('.')[0]
      log_bucket_url = get_bucket_url(log_bucket_name)
      prefix = resp.distribution.distribution_config.logging.prefix
      permission_type = (get_bucket_permission(log_bucket_name) if log_bucket_name) || nil
    end
    cloudfront_template = File.read(@template_config.cloudfront_template)
    cloudfront_template_data = ERB.new(cloudfront_template).result(binding)
    template_wth_data = @template_config.process_template_data(cloudfront_template_data)
    template_wth_data
  end
end
