$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'
require 'logging'
require_relative 'config'

# class to deal with s3 buckets
class S3
  include Logging
  S3_LIST_PERMISSION = 'list'.freeze
  S3_READ_PERMISSION = 'read'.freeze
  S3_DEFAULT_REGION = 'us-east-1'.freeze
  def get_s3_client(region)
    client = if region
               Aws::S3::Client.new(region: region)
             else
               Aws::S3::Client.new
             end
    client
  end

  # it returns bucket region or nil if access denied
  def get_bucket_region(bucket_name)
    client = get_s3_client(nil)
    options = { bucket: bucket_name, use_accelerate_endpoint: false }
    begin
      resp = client.get_bucket_location(options)
      # Note : if bucket is in us-east-1 => this value is empty string
      if resp.location_constraint && !resp.location_constraint.empty?
        resp.location_constraint
      else
        S3_DEFAULT_REGION
      end
    rescue StandardError
      nil
    end
  end

  # checking bucket permission by fetching a object. If there is AccessDenied error > No read permission
  def get_bucket_permission(target_bucket_name)
    logger.info("fetching permissions of #{target_bucket_name}")
    permission = nil
    region = get_bucket_region(target_bucket_name)
    if region
      bucket = Aws::S3::Bucket.new(name: target_bucket_name, region: region)
      client = get_s3_client(region)
      begin
        bucket.objects.limit(1).each do |object|
          permission = S3_LIST_PERMISSION
          client.get_object(bucket: target_bucket_name, key: object.key)
          permission = S3_READ_PERMISSION
        end
      rescue StandardError
      end
    end
    permission
  end

  def get_bucket_url(target_bucket_name)
    bucket_url = nil
    region = get_bucket_region(target_bucket_name)
    if region
      bucket = Aws::S3::Bucket.new(region: region, name: target_bucket_name)
      bucket_url = bucket.url
    end
    bucket_url
  end
end
