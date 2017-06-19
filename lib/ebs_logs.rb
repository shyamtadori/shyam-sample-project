require 's3'
require 'logging'
# class to deal with elastic loadbanlcer logs
class EBSLogs < S3
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def fetch_log_data(regions)
    @is_presence_only = false
    @ebs_logs = []
    regions.each do |region|
      fetch_log_data_of_region(region)
    end
    @ebs_logs
  end

  def fetch_log_data_of_region(region)
    logger.info("fetching log data of region:#{region}")
    ebs_client = get_ebs_client(region)

    applications = get_applications(ebs_client)
    s3 = S3.new
    ebs_template = File.read(@template_config.ebs_template)
    applications.each do |application|
      log_bucket_name = application.source_bundle.s3_bucket
      is_logging_enabled = true if log_bucket_name
      log_bucket_region = s3.get_bucket_region(log_bucket_name)
      log_permission = s3.get_bucket_permission(log_bucket_name)
      ebs_template_data = ERB.new(ebs_template).result(binding)
      @ebs_logs << @template_config.process_template_data(ebs_template_data)
    end
  end

  def fetch_log_presence(regions)
    @is_presence_only = true
    @ebs_logs = []
    regions.each do |region|
      fetch_log_presence_of_region(region)
    end
    @ebs_logs
  end

  def fetch_log_presence_of_region(region)
    logger.info("fetching log presence of region:#{region}")
    ebs_client = get_ebs_client(region)
    applications = get_applications(ebs_client)
    ebs_template = File.read(@template_config.ebs_template)
    applications.each do |application|
      log_bucket_name = application.source_bundle.s3_bucket
      is_logging_enabled = true if log_bucket_name
      ebs_template_data = ERB.new(ebs_template).result(binding)
      @ebs_logs << @template_config.process_template_data(ebs_template_data)
    end
  end

  def get_applications(ebs_client)
    next_token = nil
    applications = []

    loop do
      options = { max_records: 1, next_token: next_token }
      resp = ebs_client.describe_application_versions(options)
      applications += resp.application_versions
      next_token = resp.next_token
      break unless next_token
    end
    applications
  end

  def get_ebs_client(region)
    ebs_client = Aws::ElasticBeanstalk::Client.new(region: region)
    ebs_client
  end
end
