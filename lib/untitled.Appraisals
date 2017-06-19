$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'

config = {:access_key_id=>'AKIAIIFAMFSCFRDOJO5Q', :secret_access_key=>'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'}
@current_user_aws_id = "9ef778737971cee5ce4e9b5939e357ac05fa0219c15ec5fb480eeaa2f1805920"

@all_buckets = []
@logging_enabled_buckets = []
@permitted_bucket_logs = []
@output = {}

def get_s3_buckets()
	@client.list_buckets().buckets
end

def is_logging_enabled?(bucket_name)
	bucket_logging = @client.get_bucket_logging({
	  bucket: "#{bucket_name}",
	  use_accelerate_endpoint: false,
	})

	puts bucket_logging

	# bucket_logging = @client.get_bucket_logging({
	#   bucket: "#{bucket_name}",
	#   use_accelerate_endpoint: false
	# })
	# (true if bucket_logging.logging_enabled) || (false)
end

def get_target_bucket(bucket_name)
	bucket_logging = @client.get_bucket_logging({
	  bucket: "#{bucket_name}",
	  use_accelerate_endpoint: false
	})
	bucket_logging.logging_enabled.target_bucket
end

def is_having_bucket_access?(target_bucket_name)
	bucket_acl = Aws::S3::BucketAcl.new(
			:region => 'us-east-1',
		  :access_key_id => 'AKIAIIFAMFSCFRDOJO5Q',
		  :secret_access_key => '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',
		  :bucket_name => "#{target_bucket_name}")

	grants = bucket_acl.grants

	grants.each do |grant|
		return true if grant.grantee.id == "#{@current_user_aws_id}"
		# puts grant.permission
	end
	return false
end

@client = Aws::S3::Client.new(
    :access_key_id => config[:access_key_id],
    :secret_access_key => config[:secret_access_key],
    :region => 'us-east-1')


buckets  = get_s3_buckets()

buckets .each do |bucket|
	@all_buckets << bucket.name
	if is_logging_enabled?(bucket.name)
		# @logging_enabled_buckets << bucket.name
		# target_bucket_name = get_target_bucket(bucket.name)
		# if is_having_bucket_access?(target_bucket_name)
		# 	@permitted_bucket_logs << bucket.name
		# 	@output = {:log_type=>"logs of #{bucket.name}", :account_id=>@current_user_aws_id, :log_location=>target_bucket_name, :region=>"", :is_accessible=>true}
		# end
	end
end

# puts "all_buckets:::::::::"
# puts @all_buckets

# puts "logging_enabled_buckets:::::::::::"
# puts @logging_enabled_buckets

# puts "permitted_bucket_logs:::::::::::"
# puts @permitted_bucket_logs

puts @output

# client = Aws::S3::Client.new(
# 	:region => 'us-east-1',
#     :access_key_id => 'AKIAIIFAMFSCFRDOJO5Q',
#     :secret_access_key => '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')




# resp = client.get_bucket_logging({
#   bucket: "caf-cust-test", # required
#   use_accelerate_endpoint: false,

# })


# resp = s3_client.get_bucket_logging({
#   bucket: "caf-cust-test", # required
#   use_accelerate_endpoint: false,
# })

# puts resp.logging_enabled.target_bucket
# puts resp.logging_enabled.target_grants.length

# bucket = Aws::S3::Bucket.new(
# 	:region => 'us-east-1',
#     :access_key_id => 'AKIAIIFAMFSCFRDOJO5Q',
#     :secret_access_key => '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',
#     :name => 'caf-cust-test')

# resp = bucket.creation_date



# bucket_acl = Aws::S3::BucketAcl.new(
# 	:region => 'us-east-1',
#     :access_key_id => 'AKIAIIFAMFSCFRDOJO5Q',
#     :secret_access_key => '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',
#     :bucket_name => 'caf-cust-test')

# grants = bucket_acl.grants

# grants.each do |grant|
# 	puts grant.grantee
# 	# puts grant.permission
# end

# bucket_logging = Aws::S3::BucketLogging.new(
# 	:region => 'us-east-1',
#     :access_key_id => 'AKIAIIFAMFSCFRDOJO5Q',
#     :secret_access_key => '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',
#     :bucket_name => 'caf-cust-test')

# puts bucket_logging.logging_enabled





# resp = client.get_bucket_logging({
#   bucket: "BucketName", # required
#   use_accelerate_endpoint: false,
# })


# puts config[:access_key_id]

# client = Aws::S3::Client.new(
# 	  :region => 'us-east-1',
#     :access_key_id => config[:access_key_id],
#     :secret_access_key => config[:secret_access_key])

# bucket_list = client.list_buckets().buckets

# bucket_list.each do |bucket|
# 	bucket_logging = client.get_bucket_logging({
# 	  bucket: "#{bucket.name}", # required
# 	  use_accelerate_endpoint: false
# 	})
# 	if bucket_logging.logging_enabled
# 		puts bucket_logging.logging_enabled.target_bucket
# 		puts bucket_logging.logging_enabled.target_grants
# 	end
# end


# rds = Aws::RDS::Resource.new(access_key_id: @creds[:access_key_id],
#   secret_access_key: @creds[:secret_access_key],
#   region: 'us-east-1')
# rds.db_instances.each do |i|
# 	puts i.inspect
#   puts "Name (ID): #{i.id}"
#   puts "Status   : #{i.db_instance_status}"
#   puts "db_name : #{i.db_name}"
#   puts "endpoint : #{i.endpoint}"
#   puts

#   db_logs = Aws::RDS::DBLogFile.new(access_key_id: @creds[:access_key_id],
#   secret_access_key: @creds[:secret_access_key],
#   instance_id: i.id,
#   name: i.db_name)

#   puts db_logs.load
# end

# rds_client = Aws::RDS::Client.new(access_key_id: @creds[:access_key_id],
#   secret_access_key: @creds[:secret_access_key],
#   region: 'us-east-1')

# resp = rds_client.describe_db_log_files({
#   db_instance_identifier: "shyam-log-test"
# })

# puts resp.describe_db_log_files[0].log_file_name

# db_logs = Aws::RDS::DBLogFile.new(instance_id: i.id, name: i.db_name)
# puts db_logs.load