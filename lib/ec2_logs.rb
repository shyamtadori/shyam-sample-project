require 'logging'
# class to deal with RDS logs
class EC2Logs
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def get_ec2_client(region)
    Aws::EC2::Client.new(region: region)
  end

  def fetch_log_data(regions)
    @ec2_logs = []
    regions.each do |region|
      fetch_log_data_of_region(region)
    end
    @ec2_logs
  end

  def fetch_log_data_of_region(region)
    logger.info("fetching log data of region:#{region}")
    flow_logs = fetch_flow_logs(region)
    ec2_template = File.read(@template_config.ec2_template)
    flow_logs.each do |flow_log|
      ec2_template_data = ERB.new(ec2_template).result(binding)
      @ec2_logs << @template_config.process_template_data(ec2_template_data)
    end
    @ec2_logs
  end

  # describe_flow_logs returns 1000 results (minimum : 5, Maximum : 1000) by default. To fetch remaining, use next_token
  def fetch_flow_logs(region)
    ec2_client = get_ec2_client(region)
    next_token = nil
    flow_logs = []

    loop do
      options = { next_token: nil, max_results: 50 }
      resp = ec2_client.describe_flow_logs(options)
      next_token = resp.next_token
      flow_logs += resp.flow_logs
      break unless next_token
    end
    flow_logs
  end
end
