# frozen_string_literal: true

RSpec.describe Asherah do
  let(:partition_id) { 'user_1' }

  before :all do
    Asherah.configure do |config|
      config.service_name = 'gem'
      config.product_id = 'sable'
      config.kms = 'static'
      config.metastore = 'memory'
      # config.verbose = true
    end
  end

  it 'has a version number' do
    expect(Asherah::VERSION).not_to be nil
  end

  it 'encrypts and decrypts data' do
    data = 'test'
    data_row_record = Asherah.encrypt(partition_id, data)
    expect(Asherah.decrypt(partition_id, data_row_record)).to eq(data)
  end

  it 'raises error when already configured' do
    expect {
      Asherah.configure do |config|
        config.kms = 'static'
      end
    }.to raise_error(Asherah::Error::AlreadyInitialized) do |e|
      expect(e.message).to eq('SetupJson failed')
    end
  end
end
