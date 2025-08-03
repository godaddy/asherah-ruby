# frozen_string_literal: true

RSpec.describe 'Asherah input validation' do
  before :each do
    Asherah.configure do |config|
      config.service_name = 'test'
      config.product_id = 'test'
      config.kms = 'test-debug-static'
      config.metastore = 'test-debug-memory'
    end
  end

  after :each do
    Asherah.shutdown
  end

  describe 'encrypt input validation' do
    it 'raises ArgumentError for nil partition_id' do
      expect {
        Asherah.encrypt(nil, 'data')
      }.to raise_error(ArgumentError, 'partition_id cannot be nil')
    end

    it 'raises ArgumentError for nil data' do
      expect {
        Asherah.encrypt('partition', nil)
      }.to raise_error(ArgumentError, 'data cannot be nil')
    end

    it 'raises ArgumentError for non-string partition_id' do
      expect {
        Asherah.encrypt(123, 'data')
      }.to raise_error(ArgumentError, 'partition_id must be a String')
    end

    it 'raises ArgumentError for non-string data' do
      expect {
        Asherah.encrypt('partition', { key: 'value' })
      }.to raise_error(ArgumentError, 'data must be a String')
    end

    it 'raises ArgumentError for empty partition_id' do
      expect {
        Asherah.encrypt('', 'data')
      }.to raise_error(ArgumentError, 'partition_id cannot be empty')
    end

    it 'raises ArgumentError for partition_id exceeding size limit' do
      large_partition = 'a' * 1025  # Just over 1KB
      expect {
        Asherah.encrypt(large_partition, 'data')
      }.to raise_error(ArgumentError, 'partition_id too long (max 1KB)')
    end

    it 'raises ArgumentError for data exceeding size limit' do
      large_data = 'a' * (100 * 1024 * 1024 + 1)  # Just over 100MB
      expect {
        Asherah.encrypt('partition', large_data)
      }.to raise_error(ArgumentError, 'data too large (max 100MB)')
    end

    it 'accepts valid inputs within size limits' do
      expect {
        Asherah.encrypt('valid_partition', 'valid_data')
      }.not_to raise_error
    end
  end

  describe 'decrypt input validation' do
    let(:valid_json) { Asherah.encrypt('partition', 'data') }

    it 'raises ArgumentError for nil partition_id' do
      expect {
        Asherah.decrypt(nil, valid_json)
      }.to raise_error(ArgumentError, 'partition_id cannot be nil')
    end

    it 'raises ArgumentError for nil json' do
      expect {
        Asherah.decrypt('partition', nil)
      }.to raise_error(ArgumentError, 'json cannot be nil')
    end

    it 'raises ArgumentError for non-string partition_id' do
      expect {
        Asherah.decrypt(123, valid_json)
      }.to raise_error(ArgumentError, 'partition_id must be a String')
    end

    it 'raises ArgumentError for non-string json' do
      expect {
        Asherah.decrypt('partition', { key: 'value' })
      }.to raise_error(ArgumentError, 'json must be a String')
    end

    it 'raises ArgumentError for empty partition_id' do
      expect {
        Asherah.decrypt('', valid_json)
      }.to raise_error(ArgumentError, 'partition_id cannot be empty')
    end

    it 'raises ArgumentError for empty json' do
      expect {
        Asherah.decrypt('partition', '')
      }.to raise_error(ArgumentError, 'json cannot be empty')
    end

    it 'raises ArgumentError for partition_id exceeding size limit' do
      large_partition = 'a' * 1025  # Just over 1KB
      expect {
        Asherah.decrypt(large_partition, valid_json)
      }.to raise_error(ArgumentError, 'partition_id too long (max 1KB)')
    end

    it 'raises ArgumentError for json exceeding size limit' do
      # Create a fake large JSON that looks valid
      large_json = '{"data": "' + 'a' * (10 * 1024 * 1024) + '"}'
      expect {
        Asherah.decrypt('partition', large_json)
      }.to raise_error(ArgumentError, 'json too large (max 10MB)')
    end

    it 'raises ArgumentError for invalid JSON format' do
      expect {
        Asherah.decrypt('partition', 'not-json')
      }.to raise_error(ArgumentError, 'json must be valid JSON format')
    end

    it 'raises ArgumentError for JSON array instead of object' do
      expect {
        Asherah.decrypt('partition', '["array", "not", "object"]')
      }.to raise_error(ArgumentError, 'json must be valid JSON format')
    end

    it 'accepts valid JSON input' do
      expect {
        result = Asherah.decrypt('partition', valid_json)
        expect(result).to eq('data')
      }.not_to raise_error
    end
  end

  describe 'set_env input validation' do
    it 'raises ArgumentError for non-Hash env parameter' do
      expect {
        Asherah.set_env('not a hash')
      }.to raise_error(ArgumentError, 'env must be a Hash')
    end

    it 'accepts empty Hash' do
      expect {
        Asherah.set_env({})
      }.not_to raise_error
    end

    it 'accepts Hash with string key-value pairs' do
      expect {
        Asherah.set_env('KEY1' => 'value1', 'KEY2' => 'value2')
      }.not_to raise_error
    end

    it 'accepts Hash with symbol keys (converted to strings in JSON)' do
      expect {
        Asherah.set_env(key1: 'value1', key2: 'value2')
      }.not_to raise_error
    end
  end
end