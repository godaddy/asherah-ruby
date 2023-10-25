# frozen_string_literal: true

RSpec.describe Asherah::Config do
  let(:base_config) {
    lambda do |config|
      config.service_name = 'gem'
      config.product_id = 'sable'
      config.kms = 'test-debug-static'
      config.metastore = 'test-debug-memory'
    end
  }

  describe '#validate_service_name' do
    it 'raises an error when service_name not set' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.service_name = nil
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.service_name not set')
      end
    end
  end

  describe '#validate_product_id' do
    it 'raises an error when product_id not set' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.product_id = nil
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.product_id not set')
      end
    end
  end

  describe '#validate_kms' do
    it 'accepts valid sql_metastore_db_type value' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.kms = 'test-debug-static'
        end
      }.not_to raise_error
      Asherah.shutdown
    end

    it 'raises an error when kms not set' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.kms = nil
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.kms not set')
      end
    end

    it 'raises an error when kms is invalid' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.kms = 'other'
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.kms must be one of these: static, aws, test-debug-static')
      end
    end
  end

  describe '#validate_kms_attributes' do
    it 'raises an error when region_map not set' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.kms = 'aws'
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.region_map not set')
      end
    end

    it 'raises an error when preferred_region is not a hash' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.kms = 'aws'
          config.region_map = 'us-west-2=arn'
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.region_map must be a Hash')
      end
    end

    it 'raises an error when preferred_region not set' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.kms = 'aws'
          config.region_map = { 'us-west-2' => 'arn' }
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.preferred_region not set')
      end
    end
  end

  describe '#validate_metastore' do
    it 'accepts valid metastore value' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.metastore = 'test-debug-memory'
        end
      }.not_to raise_error
      Asherah.shutdown
    end

    it 'raises an error when metastore not set' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.metastore = nil
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.metastore not set')
      end
    end

    it 'raises an error when metastore is invalid' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.metastore = 'other'
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.metastore must be one of these: rdbms, dynamodb, memory, test-debug-memory')
      end
    end
  end

  describe '#validate_sql_metastore_db_type' do
    it 'accepts valid sql_metastore_db_type value' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.sql_metastore_db_type = 'postgres'
        end
      }.not_to raise_error
      Asherah.shutdown
    end

    it 'raises an error when sql_metastore_db_type is invalid' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.sql_metastore_db_type = 'other'
        end
      }.to raise_error(Asherah::Error::ConfigError) do |e|
        expect(e.message).to eq('config.sql_metastore_db_type must be one of these: mysql, postgres, oracle')
      end
    end
  end
end
