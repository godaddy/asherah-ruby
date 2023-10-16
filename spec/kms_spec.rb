# frozen_string_literal: true

RSpec.describe 'Asherah KMS integration' do
  let(:partition_id) { 'user_1' }

  it 'encrypts and decrypts using KMS' do
    kms_key_arn = ENV.fetch('KMS_KEY_ARN') do
      @disable_shutdown = true
      skip 'KMS_KEY_ARN env var is not set'
    end

    Asherah.configure do |config|
      config.service_name = 'gem'
      config.product_id = 'sable'
      config.kms = 'aws'
      config.preferred_region = 'us-west-2'
      config.region_map = { 'us-west-2' => kms_key_arn }
      config.metastore = 'memory'
      config.verbose = true
    end

    data = 'test'
    json = Asherah.encrypt(partition_id, data)
    expect(Asherah.decrypt(partition_id, json)).to eq(data)
  ensure
    Asherah.shutdown unless @disable_shutdown
  end
end
