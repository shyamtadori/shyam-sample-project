require 's3'
require 'config'
describe 'S3' do
  before(:all) do
    configuration_file_path = File.expand_path('../../data/configuration.yml', __FILE__)
    Config.new(configuration_file_path)
  end

  describe '#get_bucket_region' do
    it 'returns region in string format' do
      bucket_name = 'caf-cust-test'
      region = S3.new.get_bucket_region(bucket_name)
      expect(region).to eq('us-east-1')
    end
  end

  describe '#get_bucket_url' do
    it 'returns url in string format' do
      bucket_name = 'caf-cust-test'
      url = S3.new.get_bucket_url(bucket_name)
      expect(url).to eq('https://caf-cust-test.s3.amazonaws.com')
    end
  end

  describe '#get_bucket_permission' do
    it 'returns permission in string format'
  end
end
