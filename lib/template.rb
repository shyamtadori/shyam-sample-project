# Template Configuration
class Template
  include Logging

  attr_reader :cloudfront_template, :cloudtrail_template, :cloudwatch_group_template, :cloudwatch_stream_template,
              :dynamodb_template, :dynamodb_stream_template, :rds_template, :rds_strem_template, :s3_template, :elb_template,
              :ec2_template, :ebs_template, :emr_template, :vpc_template

  # Initilizing in start.rb
  def initialize(output_format, app_config)
    @output_format = output_format
    @cloudfront_template = validate_template(app_config['templates']["#{@output_format}"]['cloudfront'])
    @cloudtrail_template = validate_template(app_config['templates']["#{@output_format}"]['cloudtrail'])
    @cloudwatch_group_template = validate_template(app_config['templates']["#{@output_format}"]['cloudwatch_group'])
    @cloudwatch_stream_template = validate_template(app_config['templates']["#{@output_format}"]['cloudwatch_stream'])
    @dynamodb_template = validate_template(app_config['templates']["#{@output_format}"]['dynamodb'])
    @dynamodb_stream_template = validate_template(app_config['templates']["#{@output_format}"]['dynamodb_stream'])
    @rds_template = validate_template(app_config['templates']["#{@output_format}"]['rds'])
    @rds_strem_template = validate_template(app_config['templates']["#{@output_format}"]['rds_log'])
    @s3_template = validate_template(app_config['templates']["#{@output_format}"]['s3'])
    @elb_template = validate_template(app_config['templates']["#{@output_format}"]['elb'])
    @ec2_template = validate_template(app_config['templates']["#{@output_format}"]['ec2'])
    @vpc_template = validate_template(app_config['templates']["#{@output_format}"]['vpc'])
    @emr_template = validate_template(app_config['templates']["#{@output_format}"]['emr'])
    @ebs_template = validate_template(app_config['templates']["#{@output_format}"]['ebs'])
  end

  # preprocessing template dta
  def process_template_data(template_data)
    case @output_format
    when 'json'
      processed_template_data = template_data.delete("\n")
    when 'text'
      processed_template_data = template_data
    end
    processed_template_data
  end

  def process_output(output)
    case @output_format
    when 'json'
      processed_output = output.to_json
    when 'text'
      processed_output = output
    end
    processed_output
  end

  def validate_template(path)
    path
  end
end
