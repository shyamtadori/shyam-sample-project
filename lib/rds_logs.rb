require 'logging'
# class to deal with RDS logs
class RdsLogs
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def get_rds_client(region)
    Aws::RDS::Client.new(region: region)
  end

  # describe_db_instances returns 100 (minimum 20, maximum 100) instances by default. To fetch remaining, use marker
  def db_instances(region)
    logger.info("fetching db instances of region #{region}")
    rds_client = get_rds_client(region)
    next_token = nil
    rds_instances = []

    loop do
      options = { marker: next_token }
      resp = rds_client.describe_db_instances(options)
      rds_instances += resp.db_instances
      next_token = resp.marker
      break unless next_token
    end
    rds_instances
  end

  def fetch_log_files(rds_client, db_instance_id)
    options = { db_instance_identifier: db_instance_id }
    resp = rds_client.describe_db_log_files(options)
    resp.describe_db_log_files
  end

  def file_accessible?(rds_client, db_instance_id, log_file_name)
    options = { db_instance_identifier: db_instance_id, log_file_name: log_file_name, number_of_lines: 1 }
    begin
      rds_client.download_db_log_file_portion(options)
      true
    rescue StandardError
      false
    end
  end

  def fetch_log_data(regions)
    @is_presence_only = false
    @rds_logs = []
    regions.each do |region|
      fetch_log_presence_of_region(region)
    end
    @rds_logs
  end

  def fetch_log_presence_of_region(region)
    logger.info("fetching log presence of region:#{region}")
    rds_instances = db_instances(region)
    rds_client = get_rds_client(region)
    rds_template = File.read(@template_config.rds_template)
    rds_instances.each do |rds_instance| 
      is_logs_present = log_files_present?(rds_client, rds_instance.db_instance_identifier)
      rds_template_data = ERB.new(rds_template).result(binding)
      @rds_logs << @template_config.process_template_data(rds_template_data)
    end
  end

  def log_files_present?(rds_client, db_instance_id)
    options = { db_instance_identifier: db_instance_id, max_records: 1 }
    resp = rds_client.describe_db_log_files(options)
    log_files = resp.describe_db_log_files
    (false if log_files.empty?) || true
  end

  def fetch_logs(region, db_instance_id)
    logs = []
    rds_client = get_rds_client(region)
    log_files = fetch_log_files(rds_client, db_instance_id)
    rds_strem_template = File.read(@template_config.rds_strem_template)
    log_files.each do |log_file|
      is_accessible = file_accessible?(rds_client, db_instance_id, log_file.log_file_name)
      rds_template_data = ERB.new(rds_strem_template).result(binding)
      logs << @template_config.process_template_data(rds_template_data)
    end
  end

  def fetch_log_presence(regions)
    @is_presence_only = true
    @rds_logs = []
    regions.each do |region|
      fetch_log_presence_of_region(region)
    end
    @rds_logs
  end
end
