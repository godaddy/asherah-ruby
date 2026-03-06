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
    r, w = IO.pipe
    original_stderr = STDERR.dup
    STDERR.reopen(w)

    yield

    STDERR.reopen(original_stderr)
    w.close
    output = r.read
    r.close
    original_stderr.close

    output
  ensure
    STDERR.reopen(original_stderr) rescue nil
    [original_stderr, w, r].each { |io| io.close rescue nil }
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

  it 'can set environment variables' do
    Asherah.set_env('VAR1' => 'VALUE1')

    # ENV set by CGO is visible in Ruby
    expect(ENV.fetch('VAR1')).to eq('VALUE1')
  end

  it 'encrypts null bytes with null_data_check enabled' do
    Asherah.shutdown

    # Configure with null_data_check enabled (will log warnings but not fail)
    Asherah.configure do |config|
      base_config.call(config)
      config.null_data_check = true
    end

    # Capture stderr output from Go library
    null_data = "\x00" * 100
    json = nil
    stderr_output = capture_stderr do
      json = Asherah.encrypt(partition_id, null_data)
    end

    # Verify the encryption still works (it logs but doesn't fail)
    expect(json).to include('Data')
    expect(json).to include('Key')

    # Verify both log messages were produced
    expect(stderr_output).to include('input data buffer is all null before encryption')
    expect(stderr_output).to include('input data buffer was nulled during encryption')
    expect(stderr_output).to include('len=100')

    # Verify it can be decrypted
    decrypted = Asherah.decrypt(partition_id, json)
    expect(decrypted).to eq(null_data)
  end
end
