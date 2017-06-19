require 'rds_logs'
require 'config'
require 'aws-sdk'
require 'template'
describe 'RdsLogs' do
  before(:all) do
    puts 'before all'
    configuration_file_path = File.expand_path('../../data/configuration.yml', __FILE__)
    config_obj = Config.new(configuration_file_path)
    app_config = config_obj.app_config
    output_format = app_config['output_format']
    @template_config = Template.new(output_format, app_config)
  end

  describe '#db_instances' do
    it 'returns collection of db instances of given aws region' do
      db_instances = RdsLogs.new(@template_config).db_instances('us-west-2')
      expect(db_instances).to respond_to(:each)
    end
  end

  describe '#fetch_log_data' do
    it 'returns valid json object' do
      rds_logs = RdsLogs.new(@rds_template).fetch_log_data(['us-west-2'])
      json_object = ('{}' if rds_logs.empty?) || rds_logs[0]
      expect { JSON.parse(json_object) }.to_not raise_error
    end
  end
end
