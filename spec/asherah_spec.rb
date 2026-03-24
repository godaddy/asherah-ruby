# frozen_string_literal: true

RSpec.describe Asherah do
  let(:partition_id) { 'user_1' }
  let(:base_config) {
    lambda do |config|
      config.service_name = 'gem'
      config.product_id = 'sable'
      config.kms = 'test-debug-static'
      config.metastore = 'test-debug-memory'
    end
  }

  def capture_stderr
    require 'tempfile'
    tmpfile = Tempfile.new('stderr')
    original_stderr = $stderr.dup
    $stderr.reopen(tmpfile)

    yield

    $stderr.reopen(original_stderr)
    tmpfile.rewind
    tmpfile.read
  ensure
    unless original_stderr.closed?
      $stderr.reopen(original_stderr)
      original_stderr.close
    end
    tmpfile.close! unless tmpfile.closed?
  end

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

  it 'encrypts to json and decrypts from json' do
    data = 'test'
    json = Asherah.encrypt(partition_id, data)
    expect(JSON.parse(json).keys.sort).to eq(['Data', 'Key'])
    expect(Asherah.decrypt(partition_id, json)).to eq(data)
  end

  it 'encrypts to json and decrypts from json different data length' do
    [0, 1024, 1024 * 1024].each do |i|
      0.upto(5) do |j|
        data = 'a' * (i + j)
        json = Asherah.encrypt(partition_id, data)
        expect(Asherah.decrypt(partition_id, json)).to eq(data)
      end
    end
  end

  it 'encrypts and decrypts UTF-8 characters' do
    data = '1 ® ▪ 😜 如'
    json = Asherah.encrypt(partition_id, data)
    expect(Asherah.decrypt(partition_id, json)).to eq(data)
  end

  it 'raises error on configure when already configured' do
    expect {
      Asherah.configure do |config|
        base_config.call(config)
      end
    }.to raise_error(Asherah::Error::AlreadyInitialized)
  end

  it 'raises error on shutdown when not initialized' do
    Asherah.shutdown # Before each work-around

    expect {
      Asherah.shutdown
    }.to raise_error(Asherah::Error::NotInitialized)

    Asherah.configure { |config| base_config.call(config) } # After each work-around
  end

end
