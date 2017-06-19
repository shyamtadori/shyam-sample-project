$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'
require 's3_logs'
require 'cloud_trail_logs'
require 'rds_logs'
require 'cloudwatch_logs'
require 'dynamodb_logs'
require 'cloud_front_logs'
require 'elb_logs'
require 'emr_logs'
require 'ec2_logs'
require 'ebs_logs'
require 'vpc_flow_logs'
require 'logging'
require 'erb'
require 'template'
# program execution starts from this class
class Log
  include Logging
  S3 = 's3'.freeze
  CLOUD_TRAIL = 'cloudtrail'.freeze
  RDS = 'rds'.freeze
  CLOUD_WATCH = 'cloudwatch'.freeze
  DYNAMODB = 'dynamodb'.freeze
  CLOUDFRONT = 'cloudfront'.freeze
  ELB = 'elb'.freeze
  EMR = 'emr'.freeze
  EC2 = 'ec2'.freeze
  EBS = 'ebs'.freeze
  VPC = 'vpc'.freeze
  REGIONS = ['us-east-1', 'us-east-2', 'us-west-1', 'us-west-2', 'ca-central-1', 'ap-south-1', 'ap-northeast-2', 'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'eu-central-1', 'eu-west-1', 'eu-west-2', 'sa-east-1'].freeze

  def initialize(app_config)
    @required_logs = app_config['logs']
    @regions = validate_regions(app_config['regions'])
    output_format = app_config['output_format']
    logger.level = fetch_log_level(app_config['mode'])
    @template_config = Template.new(output_format, app_config)
    @presence_only = app_config['presence_only'] # output level (only log presence | full log data)
    @output = {}
  end

  # calling from bin/run
  def start
    @required_logs.each do |log_type|
      case log_type
      when Log::S3
        logger.info('************ Fetching S3 Logs *************')
        @output['s3'] = []
        s3_logs = S3Logs.new(@template_config)
        @output['s3'] = s3_logs.fetch_log_data(@regions, @presence_only)
      when Log::CLOUD_TRAIL
        logger.info('************ Fetching Cloud Trail Logs *************')
        @output['cloudtrail'] = []
        cloud_trail_logs = CloudTrailLogs.new(@template_config)
        @output['cloudtrail'] = (cloud_trail_logs.fetch_log_presence(@regions) if @presence_only) || cloud_trail_logs.fetch_log_data(@regions)
      when Log::RDS
        logger.info('************ Fetching RDS Logs *************')
        @output['rds'] = []
        rds_logs = RdsLogs.new(@template_config)
        @output['rds'] = (rds_logs.fetch_log_presence(@regions) if @presence_only) || rds_logs.fetch_log_data(@regions)
      when Log::CLOUD_WATCH
        logger.info('************ Fetching CLOUD_WATCH Logs *************')
        @output['cloudwatch'] = []
        cloudwatch_logs = CloudWatchLogs.new(@template_config)
        @output['cloudwatch'] = cloudwatch_logs.fetch_log_data(@regions, @presence_only)
      when Log::DYNAMODB
        logger.info('************ Fetching DYNAMODB Logs *************')
        @output['dynamodb'] = []
        dynamodb_logs = DynamodbLogs.new(@template_config)
        @output['dynamodb'] = (dynamodb_logs.fetch_log_presence(@regions) if @presence_only) || dynamodb_logs.fetch_log_data(@regions)
      when Log::CLOUDFRONT
        logger.info('************ Fetching CLOUDFRONT Logs *************')
        @output['cloudfront'] = []
        cloudfront_logs = CloudFrontLogs.new(@template_config)
        @output['cloudfront'] = (cloudfront_logs.fetch_log_presence if @presence_only) || cloudfront_logs.fetch_log_data
      when Log::ELB
        logger.info('************ Fetching ELB Logs *************')
        @output['elb'] = []
        elb_logs = ELBLogs.new(@template_config)
        @output['elb'] = elb_logs.fetch_log_data(@regions, @presence_only)
      when Log::EMR
        logger.info('************ Fetching EMR Logs *************')
        @output['emr'] = []
        emr_logs = EMRLogs.new(@template_config)
        @output['emr'] = emr_logs.fetch_log_data(@regions, @presence_only)
      when Log::EC2
        logger.info('************ Fetching EC2 Logs *************')
        @output['ec2'] = []
        ec2_logs = EC2Logs.new(@template_config)
        @output['ec2'] = ec2_logs.fetch_log_data(@regions)
      when Log::EBS
        logger.info('************ Fetching EBS Logs *************')
        @output['ebs'] = []
        ebs_logs = EBSLogs.new(@template_config)
        @output['ebs'] = (ebs_logs.fetch_log_presence(@regions) if @presence_only) || ebs_logs.fetch_log_data(@regions)
      when Log::VPC
        logger.info('************ Fetching VPC Flow Logs *************')
        @output['vpc'] = []
        vpc_logs = VPCFlowLogs.new(@template_config)
        @output['vpc'] = (vpc_logs.fetch_log_presence(@regions) if @presence_only) || vpc_logs.fetch_log_data(@regions)
      else
        raise "Invalid Log type: #{log_type}"
      end
    end
    puts @output.to_json
  end

  # Validating the regions passing from configuration file. If regions is an empty array, assigning all aws regions
  def validate_regions(regions)
    raise 'Invalid regions' unless regions.instance_of? Array
    regions = REGIONS if regions.length.zero?
    regions
  end

  # mapping mode to log level
  def fetch_log_level(mode)
    case mode
    when 'verbose'
      Logger::INFO
    when 'debug'
      Logger::DEBUG
    else # silent mode
      Logger::ERROR
    end
  end
end
