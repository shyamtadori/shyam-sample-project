require 'yaml'
require 'logging'
# Configuring
class Config
  include Logging
  attr_reader :app_config
  # Initilizing while starting the program in bin/run
  def initialize(file_path)
    @app_config = load_and_verify_yaml_config_file(file_path)
    configure_aws(@app_config)
  end

  # Configuring aws
  def configure_aws(app_config)
    options = { credentials: Aws::Credentials.new(app_config['access_key_id'], app_config['secret_access_key']) }
    Aws.config.update(options)
  end

  def load_and_verify_yaml_config_file(file_path)
    begin
      YAML::load(File.open(file_path))
    rescue StandardError => e
      logger.error e
      exit
    end
  end

  def app_config
    @app_config
  end
end
