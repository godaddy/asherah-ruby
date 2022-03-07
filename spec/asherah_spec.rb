# frozen_string_literal: true

RSpec.describe Asherah do
  let(:partition_id) { 'user_1' }
  setup_options = {
    kms_type: 'static',
    metastore: 'memory',
    service_name: 'gem',
    product_id: 'sable',
  }

  before :all do
    Asherah.setup(**setup_options)
  end

  it 'has a version number' do
    expect(Asherah::VERSION).not_to be nil
  end

  it 'encrypts and decrypts data' do
    data = 'test'
    data_row = Asherah.encrypt(partition_id, data)
    expect(Asherah.decrypt(partition_id, data_row)).to eq(data)
  end

  it 'raises error when already initialized' do
    expect {
      Asherah.setup(**setup_options)
    }.to raise_error(Asherah::Error::ResultError) do |e|
      expect(e.message).to eq('setup failed: already initialized')
    end
  end
end
