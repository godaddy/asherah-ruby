# frozen_string_literal: true

require 'json'

module Asherah
  # @attr [String] kms, The master key management service (static or kms)
  # @attr [String] metastore, The type of metastore for persisting keys (rdbms, dynamodb, memory)
  # @attr [String] service_name, The name of this service
  # @attr [String] product_id, The name of the product that owns this service
  # @attr [String] connection_string, The database connection string (required when metastore is rdbms)
  # @attr [String] replica_read_consistency, For Aurora sessions using write forwarding (eventual, global, session)
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
      kms: :KMS,
      metastore: :Metastore,
      service_name: :ServiceName,
      product_id: :ProductID,
      connection_string: :ConnectionString,
      replica_read_consistency: :ReplicaReadConsistency,
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

    attr_accessor(*MAPPING.keys)

    def to_json(*args)
      config = {}.tap do |c|
        MAPPING.each_pair do |our_key, their_key|
          value = public_send(our_key)
          c[their_key] = value unless value.nil?
        end
      end

      JSON.generate(config, *args)
    end
  end
end
