# frozen_string_literal: true

RSpec.describe Asherah do
  let(:partition_id) { 'user:1' }

  before :all do
    Asherah.setup(
      kms_type: 'static',
      metastore: 'memory',
      service_name: 'gem',
      product_id: 'sable'
    )
  end

  it 'has a version number' do
    expect(Asherah::VERSION).not_to be nil
  end

  it 'encrypts and decrypts data' do
    data = 'test'
    data_row = Asherah.encrypt(partition_id, data)
    expect(Asherah.decrypt(partition_id, data_row)).to eq(data)
  end
end
