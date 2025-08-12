# frozen_string_literal: true

require 'json'

module Asherah
  # @attr [String] service_name, The name of this service
  # @attr [String] product_id, The name of the product that owns this service
  # @attr [String] kms, The master key management service (static or aws)
  # @attr [String] metastore, The type of metastore for persisting keys (rdbms, dynamodb, memory)
  # @attr [String] connection_string, The database connection string (required when metastore is rdbms)
  # @attr [String] replica_read_consistency, For Aurora sessions using write forwarding (eventual, global, session)
  # @attr [String] sql_metastore_db_type, Which SQL driver to use (mysql, postgres, oracle), defaults to mysql
  # @attr [String] dynamo_db_endpoint, An optional endpoint URL (for dynamodb metastore)
  # @attr [String] dynamo_db_region, The AWS region for DynamoDB requests (for dynamodb metastore)
  # @attr [String] dynamo_db_table_name, The table name for DynamoDB (for dynamodb metastore)
  # @attr [Boolean] enable_region_suffix, Configure the metastore to use regional suffixes (for dynamodb metastore)
  # @attr [String] region_map, List of key-value pairs in the form of REGION1=ARN1[,REGION2=ARN2] (required for aws kms)
  # @attr [String] preferred_region, The preferred AWS region (required for aws kms)
  # @attr [Integer] session_cache_max_size, The maximum number of sessions to cache
  # @attr [Integer] session_cache_duration, The amount of time in seconds a session will remain cached
  # @attr [Integer] expire_after, The amount of time in seconds a key is considered valid
  # @attr [Integer] check_interval, The amount of time in seconds before cached keys are considered stale
  # @attr [Boolean] enable_session_caching, Enable shared session caching
  # @attr [Boolean] verbose, Enable verbose logging output
  class Config
    MAPPING = {
      service_name: :ServiceName,
      product_id: :ProductID,
      kms: :KMS,
      metastore: :Metastore,
      connection_string: :ConnectionString,
      replica_read_consistency: :ReplicaReadConsistency,
      sql_metastore_db_type: :SQLMetastoreDBType,
      dynamo_db_endpoint: :DynamoDBEndpoint,
      dynamo_db_region: :DynamoDBRegion,
      dynamo_db_table_name: :DynamoDBTableName,
      enable_region_suffix: :EnableRegionSuffix,
      region_map: :RegionMap,
      preferred_region: :PreferredRegion,
      session_cache_max_size: :SessionCacheMaxSize,
      session_cache_duration: :SessionCacheDuration,
      enable_session_caching: :EnableSessionCaching,
      expire_after: :ExpireAfter,
      check_interval: :CheckInterval,
      verbose: :Verbose
    }.freeze

    KMS_TYPES = ['static', 'aws', 'test-debug-static'].freeze
    METASTORE_TYPES = ['rdbms', 'dynamodb', 'memory', 'test-debug-memory'].freeze
    SQL_METASTORE_DB_TYPES = ['mysql', 'postgres', 'oracle'].freeze

    attr_accessor(*MAPPING.keys)

    def validate!
      validate_service_name
      validate_product_id
      validate_kms
      validate_metastore
      validate_sql_metastore_db_type
      validate_kms_attributes
    end

    def to_json(*args)
      config = {}.tap do |c|
        MAPPING.each_pair do |our_key, their_key|
          value = public_send(our_key)
          c[their_key] = value unless value.nil?
        end
      end

      JSON.generate(config, *args)
    end

    private

    def validate_service_name
      raise Error::ConfigError, 'config.service_name not set' if service_name.nil?
    end

    def validate_product_id
      raise Error::ConfigError, 'config.product_id not set' if product_id.nil?
    end

    def validate_kms
      raise Error::ConfigError, 'config.kms not set' if kms.nil?
      unless KMS_TYPES.include?(kms)
        raise Error::ConfigError, "config.kms must be one of these: #{KMS_TYPES.join(', ')}"
      end
    end

    def validate_metastore
      raise Error::ConfigError, 'config.metastore not set' if metastore.nil?
      unless METASTORE_TYPES.include?(metastore)
        raise Error::ConfigError, "config.metastore must be one of these: #{METASTORE_TYPES.join(', ')}"
      end
    end

    def validate_sql_metastore_db_type
      return if sql_metastore_db_type.nil?

      unless SQL_METASTORE_DB_TYPES.include?(sql_metastore_db_type)
        raise Error::ConfigError,
              "config.sql_metastore_db_type must be one of these: #{SQL_METASTORE_DB_TYPES.join(', ')}"
      end
    end

    def validate_kms_attributes
      return unless kms == 'aws'
      raise Error::ConfigError, 'config.region_map not set' if region_map.nil?
      raise Error::ConfigError, 'config.region_map must be a Hash' unless region_map.is_a?(Hash)
      raise Error::ConfigError, 'config.preferred_region not set' if preferred_region.nil?
    end
  end
end
