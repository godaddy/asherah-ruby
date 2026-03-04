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

  describe '#disable_zero_copy' do
    it 'accepts disable_zero_copy as true' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.disable_zero_copy = true
        end
      }.not_to raise_error
      Asherah.shutdown
    end

    it 'accepts disable_zero_copy as false' do
      expect {
        Asherah.configure do |config|
          base_config.call(config)
          config.disable_zero_copy = false
        end
      }.not_to raise_error
      Asherah.shutdown
    end
  end

  describe '#to_json' do
    it 'correctly maps all configuration options to Go JSON format' do
      config = Asherah::Config.new
      config.service_name = 'test-service'
      config.product_id = 'test-product'
      config.kms = 'aws'
      config.metastore = 'dynamodb'
      config.connection_string = 'mysql://localhost:3306/test'
      config.replica_read_consistency = 'eventual'
      config.sql_metastore_db_type = 'postgres'
      config.dynamo_db_endpoint = 'http://localhost:8000'
      config.dynamo_db_region = 'us-west-2'
      config.dynamo_db_table_name = 'test-table'
      config.enable_region_suffix = true
      config.region_map = { 'us-west-2' => 'arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012' }
      config.preferred_region = 'us-west-2'
      config.session_cache_max_size = 500
      config.session_cache_duration = 3600
      config.enable_session_caching = true
      config.disable_zero_copy = true
      config.expire_after = 7200
      config.check_interval = 1800
      config.verbose = true

      json_output = JSON.parse(config.to_json)

      expect(json_output).to eq({
        'ServiceName' => 'test-service',
        'ProductID' => 'test-product',
        'KMS' => 'aws',
        'Metastore' => 'dynamodb',
        'ConnectionString' => 'mysql://localhost:3306/test',
        'ReplicaReadConsistency' => 'eventual',
        'SQLMetastoreDBType' => 'postgres',
        'DynamoDBEndpoint' => 'http://localhost:8000',
        'DynamoDBRegion' => 'us-west-2',
        'DynamoDBTableName' => 'test-table',
        'EnableRegionSuffix' => true,
        'RegionMap' => { 'us-west-2' => 'arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012' },
        'PreferredRegion' => 'us-west-2',
        'SessionCacheMaxSize' => 500,
        'SessionCacheDuration' => 3600,
        'EnableSessionCaching' => true,
        'DisableZeroCopy' => true,
        'ExpireAfter' => 7200,
        'CheckInterval' => 1800,
        'Verbose' => true
      })
    end

    it 'excludes nil values from JSON output' do
      config = Asherah::Config.new
      config.service_name = 'test-service'
      config.product_id = 'test-product'
      config.kms = 'test-debug-static'
      config.metastore = 'test-debug-memory'

      json_output = JSON.parse(config.to_json)

      expect(json_output).to eq({
        'ServiceName' => 'test-service',
        'ProductID' => 'test-product',
        'KMS' => 'test-debug-static',
        'Metastore' => 'test-debug-memory'
      })
    end
  end
end
