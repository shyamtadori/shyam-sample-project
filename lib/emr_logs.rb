require 's3'
require 'logging'
# class to deal with elastic loadbanlcer logs
class EMRLogs < S3
  include Logging

  def initialize(template_config)
    @template_config = template_config
  end

  def fetch_log_data(regions, is_presence_only)
    @is_presence_only = is_presence_only
    @emr_logs = []
    regions.each do |region|
      fetch_log_data_of_region(region)
    end
    @emr_logs
  end

  def fetch_log_data_of_region(region)
    logger.info("fetching log data of region:#{region}")
    emr_client = get_emr_client(region)
    clusters = get_clusters(emr_client)
    emr_template = File.read(@template_config.emr_template)

    s3 = S3.new if !@is_presence_only
    clusters.each do |cluster_obj|
      options = { cluster_id: cluster_obj.id }
      resp = emr_client.describe_cluster(options)
      cluster = resp.cluster
      is_logging_enabled = (true if cluster.log_uri) || false
      if is_logging_enabled && !@is_presence_only
        log_bucket_name = fetch_bucket_name_from_uri(cluster.log_uri)
        log_bucket_region = s3.get_bucket_region(log_bucket_name)
        log_permission = s3.get_bucket_permission(log_bucket_name)
      end
      emr_template_data = ERB.new(emr_template).result(binding)
      @emr_logs << @template_config.process_template_data(emr_template_data)
    end
    @emr_logs
  end

  def get_clusters(emr_client)
    next_token = nil
    clusters = []

    loop do
      options = { marker: next_token }
      resp = emr_client.list_clusters(options)
      clusters += resp.clusters
      next_token = resp.marker
      break unless next_token
    end
    clusters
  end

  def get_emr_client(region)
    emr_client = Aws::EMR::Client.new(region: region)
    emr_client
  end

  def fetch_bucket_name_from_uri(log_uri)
    log_uri.split('//')[1].split('/')[0]
  end
end
