require 'elb_logs'
require 'config'
require 'aws-sdk'
require 'template'
describe 'ELBLogs' do
  before(:all) do
    configuration_file_path = File.expand_path('../../data/configuration.yml', __FILE__)
    config_obj = Config.new(configuration_file_path)
    app_config = config_obj.app_config
    output_format = app_config['output_format']
    @template_config = Template.new(output_format, app_config)
  end

  describe '#fetch_log_data' do
    it 'returns valid json object' do
      elb_logs = ELBLogs.new(@template_config).fetch_log_data(['us-east-1'])
      json_object = ('{}' if elb_logs.empty?) || elb_logs[0]
      expect { JSON.parse(json_object) }.to_not raise_error
    end
  end
end
