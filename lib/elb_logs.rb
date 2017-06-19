require 's3'
require 'logging'
# class to deal with elastic loadbanlcer logs
class ELBLogs < S3
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def fetch_log_data(regions, is_presence_only)
    @is_presence_only = is_presence_only
    @elb_logs = []
    regions.each do |region|
      fetch_log_data_of_region(region)
    end
    @elb_logs
  end

  def fetch_log_data_of_region(region)
    logger.info("fetching log data of region:#{region}")
    elb_client = get_elb_client(region)
    load_balancers = get_load_balancers(elb_client)
    elb_template = File.read(@template_config.elb_template)
    load_balancers.each do |load_balancer|
      elb_attributes = fetch_elb_attributes(elb_client, load_balancer)
      is_logging_enabled = (elb_attributes[:is_log_enabled] == 'true')
      elb_template_data = ERB.new(elb_template).result(binding)
      @elb_logs << @template_config.process_template_data(elb_template_data)
    end
  end

  def fetch_elb_attributes(elb_client, load_balancer)
    logger.info("fetching attributes of :#{load_balancer.load_balancer_arn}")
    options = { load_balancer_arn: load_balancer.load_balancer_arn }
    attributes = elb_client.describe_load_balancer_attributes(options).attributes
    attributes_hash = build_elb_attrubutes(attributes)
    attributes_hash
  end

  def get_load_balancers(elb_client)
    next_token = nil
    load_balancers = []

    loop do
      options = { marker: next_token }
      resp = elb_client.describe_load_balancers(options)
      load_balancers += resp.load_balancers
      next_token = resp.next_marker
      break unless next_token
    end
    load_balancers
  end

  def get_elb_client(region)
    elb_client = Aws::ElasticLoadBalancingV2::Client.new(region: region)
    elb_client
  end

  # constructing attributes hash to use in template
  def build_elb_attrubutes(attributes)
    attributes_hash = {}
    attributes.each do |attribute|
      case attribute.key
      when 'access_logs.s3.bucket'
        attributes_hash[:log_bucket] = attribute.value
      when 'access_logs.s3.enabled'
        attributes_hash[:is_log_enabled] = attribute.value
      when 'access_logs.s3.prefix'
        attributes_hash[:prefix] = attribute.value
      end
    end
    attributes_hash
  end
end
