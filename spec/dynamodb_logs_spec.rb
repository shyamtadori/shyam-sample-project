require 'dynamodb_logs'
require 'config'
require 'aws-sdk'
require 'template'
describe 'DynamodbLogs' do
  before(:all) do
    puts 'before all'
    configuration_file_path = File.expand_path('../../data/configuration.yml', __FILE__)
    config_obj = Config.new(configuration_file_path)
    app_config = config_obj.app_config
    output_format = app_config['output_format']
    @template_config = Template.new(output_format, app_config)
  end

  describe '#fetch_log_data' do
    it 'returns valid json object' do
      dynamodb_logs = DynamodbLogs.new(@template_config).fetch_log_data(['us-east-1'])

      json_object = ('{}' if dynamodb_logs.empty?) || dynamodb_logs[0]
      expect { JSON.parse(json_object) }.to_not raise_error
    end
  end
end
