require 'cloudwatch_logs'
require 'config'
require 'aws-sdk'
require 'template'
describe 'CloudwatchLogs' do
  before(:all) do
    configuration_file_path = File.expand_path('../../data/configuration.yml', __FILE__)
    config_obj = Config.new(configuration_file_path)
    app_config = config_obj.app_config
    output_format = app_config['output_format']
    @template_config = Template.new(output_format, app_config)
  end

  describe '#fetch_log_data' do
    it 'returns valid cloudwatch group json object' do
      cloudwatch_logs = CloudWatchLogs.new(@template_config).fetch_log_data(['us-east-1'])
      json_object = ('{}' if cloudwatch_logs.empty?) || cloudwatch_logs[0]
      expect { JSON.parse(json_object) }.to_not raise_error
    end
    it 'returns valid cloudwatch stream json object' do
      cloudwatch_logs = CloudWatchLogs.new(@template_config).fetch_log_data(['us-east-1'])
      cloudwatch_group = ('{}' if cloudwatch_logs.empty?) || JSON.parse(cloudwatch_logs[0])

      cloudwatch_streams = cloudwatch_group['log_streams'] || []
      json_object = ('{}' if cloudwatch_streams.empty?) || cloudwatch_streams[0]
      expect { JSON.parse(json_object) }.to_not raise_error
    end
  end
end
