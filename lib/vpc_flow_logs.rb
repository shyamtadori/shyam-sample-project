require 'logging'
# class to deal with RDS logs
class VPCFlowLogs
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def get_ec2_client(region)
    Aws::EC2::Client.new(region: region)
  end

  def get_ec2_resource(client)
    Aws::EC2::Resource.new(client: client)
  end

  def fetch_log_data(regions)
    @is_presence_only = false
    @vpc_flow_logs = []
    regions.each do |region|
      fetch_log_data_of_region(region)
    end
    @vpc_flow_logs
  end

  def fetch_log_data_of_region(region)
    logger.info("fetching log data of region:#{region}")
    ec2_client = get_ec2_client(region)
    ec2_resource = get_ec2_resource(ec2_client)
    vpc_ids = get_vpc_ids(ec2_resource)

    vpc_ids.each do |vpc_id|
      flow_logs = fetch_flow_logs(ec2_client, vpc_id)
      vpc_template = File.read(@template_config.vpc_template)
      if flow_logs.empty?
        is_logging_enabled = false
        vpc_template_data = ERB.new(vpc_template).result(binding)
        @vpc_flow_logs << @template_config.process_template_data(vpc_template_data)
      else
        is_logging_enabled = true
        flow_logs.each do |flow_log|
          vpc_template_data = ERB.new(vpc_template).result(binding)
          @vpc_flow_logs << @template_config.process_template_data(vpc_template_data)
        end
      end
    end
    @vpc_flow_logs
  end

  def fetch_log_presence(regions)
    @is_presence_only = true
    @vpc_flow_logs = []
    regions.each do |region|
      fetch_log_presence_of_region(region)
    end
    @vpc_flow_logs
  end

  def fetch_log_presence_of_region(region)
    logger.info("fetching log presence of region:#{region}")
    ec2_client = get_ec2_client(region)
    ec2_resource = get_ec2_resource(ec2_client)
    vpc_ids = get_vpc_ids(ec2_resource)
    vpc_template = File.read(@template_config.vpc_template)
    vpc_ids.each do |vpc_id|
      is_logging_enabled = flow_logs_present?(ec2_client, vpc_id)
      vpc_template_data = ERB.new(vpc_template).result(binding)
      @vpc_flow_logs << @template_config.process_template_data(vpc_template_data)
    end
    @vpc_flow_logs
  end

  def get_vpc_ids(ec2_resource)
    vpc_ids = []
    ec2_resource.network_interfaces.each do |networkinterface|
      vpc_ids << networkinterface.vpc_id
    end
    vpc_ids.uniq
  end

  def flow_logs_present?(ec2_client, vpc_id)
    options = { max_results: 1, filter: [{ name: 'resource-id', values: [vpc_id] }] }
    resp = ec2_client.describe_flow_logs(options)
    !resp.flow_logs.empty?
  end

  # describe_flow_logs returns 1000 results (minimum : 5, Maximum : 1000) by default. To fetch remaining, use next_token
  def fetch_flow_logs(ec2_client, vpc_id)
    logger.info("fetching flow logs of vpc:#{vpc_id}")
    next_token = nil
    flow_logs = []

    begin
      options = { next_token: nil, max_results: 50, filter: [{ name: 'resource-id', values: [vpc_id] }] }
      resp = ec2_client.describe_flow_logs(options)
      next_token = resp.next_token
      flow_logs += resp.flow_logs
    end while next_token
    flow_logs
  end
end
