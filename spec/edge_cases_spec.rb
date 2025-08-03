# frozen_string_literal: true

RSpec.describe 'Asherah edge cases' do
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

  describe 'boundary conditions' do
    it 'handles empty string data encryption and decryption' do
      json = Asherah.encrypt('partition', '')
      result = Asherah.decrypt('partition', json)
      expect(result).to eq('')
    end

    it 'handles single character data' do
      json = Asherah.encrypt('partition', 'a')
      result = Asherah.decrypt('partition', json)
      expect(result).to eq('a')
    end

    it 'handles data at size boundaries' do
      # Test at 1KB boundary
      data_1kb = 'x' * 1024
      json = Asherah.encrypt('partition', data_1kb)
      result = Asherah.decrypt('partition', json)
      expect(result).to eq(data_1kb)

      # Test at 1MB boundary
      data_1mb = 'y' * (1024 * 1024)
      json = Asherah.encrypt('partition', data_1mb)
      result = Asherah.decrypt('partition', json)
      expect(result).to eq(data_1mb)
    end

    it 'handles maximum allowed partition_id size' do
      partition_1kb = 'p' * 1024  # Exactly 1KB
      json = Asherah.encrypt(partition_1kb, 'data')
      result = Asherah.decrypt(partition_1kb, json)
      expect(result).to eq('data')
    end
  end

  describe 'special characters and encoding' do
    it 'handles data with newlines and tabs' do
      data = "line1\nline2\ttabbed"
      json = Asherah.encrypt('partition', data)
      result = Asherah.decrypt('partition', json)
      expect(result).to eq(data)
    end

    it 'handles data with null bytes' do
      data = "data\x00with\x00nulls"
      json = Asherah.encrypt('partition', data)
      result = Asherah.decrypt('partition', json)
      expect(result).to eq(data)
    end

    it 'handles binary data' do
      data = (0..255).map(&:chr).join
      json = Asherah.encrypt('partition', data)
      result = Asherah.decrypt('partition', json)
      expect(result.bytes).to eq(data.bytes)
    end

    it 'handles JSON special characters in data' do
      data = '{"key": "value", "array": [1, 2, 3], "nested": {"a": true}}'
      json = Asherah.encrypt('partition', data)
      result = Asherah.decrypt('partition', json)
      expect(result).to eq(data)
    end

    it 'handles Unicode emoji in partition_id' do
      partition = 'user_😀_test'
      json = Asherah.encrypt(partition, 'data')
      result = Asherah.decrypt(partition, json)
      expect(result).to eq('data')
    end
  end

  describe 'concurrent access patterns' do
    it 'handles multiple encryptions with same partition_id' do
      results = []
      5.times do |i|
        data = "data_#{i}"
        json = Asherah.encrypt('same_partition', data)
        results << { json: json, expected: data }
      end

      results.each do |item|
        decrypted = Asherah.decrypt('same_partition', item[:json])
        expect(decrypted).to eq(item[:expected])
      end
    end

    it 'handles interleaved operations with different partitions' do
      json1 = Asherah.encrypt('partition1', 'data1')
      json2 = Asherah.encrypt('partition2', 'data2')
      
      result2 = Asherah.decrypt('partition2', json2)
      result1 = Asherah.decrypt('partition1', json1)
      
      expect(result1).to eq('data1')
      expect(result2).to eq('data2')
    end
  end

  describe 'DataRowRecord structure validation' do
    it 'produces valid JSON structure from encrypt' do
      json_string = Asherah.encrypt('partition', 'data')
      
      # Parse and validate structure
      parsed = JSON.parse(json_string)
      expect(parsed).to be_a(Hash)
      expect(parsed).to have_key('Data')
      expect(parsed).to have_key('Key')
      
      # Validate nested structure
      expect(parsed['Key']).to be_a(Hash)
      expect(parsed['Key']).to have_key('Created')
      expect(parsed['Key']).to have_key('EncryptedKey')
      expect(parsed['Key']).to have_key('ParentKeyMeta')
    end

    it 'rejects decrypt with malformed JSON structure' do
      malformed_json = '{"Data": "test", "MissingKey": true}'
      expect {
        Asherah.decrypt('partition', malformed_json)
      }.to raise_error # Will fail in C library with missing Key field
    end
  end

  describe 'memory efficiency patterns' do
    it 'handles repeated encryption/decryption cycles' do
      100.times do |i|
        data = "iteration_#{i}_data"
        json = Asherah.encrypt('partition', data)
        result = Asherah.decrypt('partition', json)
        expect(result).to eq(data)
      end
    end

    it 'handles varying data sizes in sequence' do
      sizes = [10, 100, 1000, 10000, 100000]
      sizes.each do |size|
        data = 'z' * size
        json = Asherah.encrypt('partition', data)
        result = Asherah.decrypt('partition', json)
        expect(result.length).to eq(size)
      end
    end
  end
end