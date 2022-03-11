# frozen_string_literal: true

RSpec.describe Asherah do
  let(:partition_id) { 'user_1' }
  let(:base_config) {
    lambda do |config|
      config.service_name = 'gem'
      config.product_id = 'sable'
      config.kms = 'static'
      config.metastore = 'memory'
    end
  }

  before :each do
    Asherah.configure do |config|
      base_config.call(config)
    end
  end

  after :each do
    Asherah.shutdown
  end

  it 'has a version number' do
    expect(Asherah::VERSION).not_to be nil
  end

  it 'encrypts and decrypts data' do
    data = 'test'
    data_row_record = Asherah.encrypt(partition_id, data)
    expect(Asherah.decrypt(partition_id, data_row_record)).to eq(data)
  end

  it 'encrypts to json and decrypts from json' do
    data = 'test'
    json = Asherah.encrypt_to_json(partition_id, data)
    expect(JSON.parse(json).keys.sort).to eq(['Data', 'Key'])
    expect(Asherah.decrypt_from_json(partition_id, json)).to eq(data)
  end

  it 'raises error when already configured' do
    expect {
      Asherah.configure do |config|
        base_config.call(config)
      end
    }.to raise_error(Asherah::Error::AlreadyInitialized) do |e|
      expect(e.message).to eq('SetupJson failed')
    end
  end
end
