# frozen_string_literal: true

require 'json'

module Asherah
  # @attr [String] kms, The master key management service (static or kms)
  # @attr [String] metastore, The type of metastore for persisting keys (rdbms, dynamodb, memory)
  # @attr [String] service_name, The name of this service
  # @attr [String] product_id, The name of the product that owns this service
  # @attr [String] connection_string, The database connection string (required when metastore is rdbms)
  # @attr [String] replica_read_consistency, Required for Aurora sessions using write forwarding (eventual, global, session)
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
    attr_accessor  \
      :kms,
      :metastore,
      :service_name,
      :product_id,
      :connection_string,
      :replica_read_consistency,
      :dynamo_db_endpoint,
      :dynamo_db_region,
      :dynamo_db_table_name,
      :enable_region_suffix,
      :region_map,
      :preferred_region,
      :session_cache_max_size,
      :session_cache_duration,
      :enable_session_caching,
      :expire_after,
      :check_interval,
      :verbose

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def to_json(*args)
      config = {
        KMS: kms,
        Metastore: metastore,
        ServiceName: service_name,
        ProductID: product_id
      }.tap do |c|
        c[:ConnectionString] = connection_string unless connection_string.nil?
        c[:ReplicaReadConsistency] = replica_read_consistency unless replica_read_consistency.nil?
        c[:DynamoDBEndpoint] = dynamo_db_endpoint unless dynamo_db_endpoint.nil?
        c[:DynamoDBRegion] = dynamo_db_region unless dynamo_db_region.nil?
        c[:DynamoDBTableName] = dynamo_db_table_name unless dynamo_db_table_name.nil?
        c[:EnableRegionSuffix] = enable_region_suffix unless enable_region_suffix.nil?
        c[:RegionMap] = region_map unless region_map.nil?
        c[:PreferredRegion] = preferred_region unless preferred_region.nil?
        c[:EnableSessionCaching] = enable_session_caching unless enable_session_caching.nil?
        c[:SessionCacheMaxSize] = session_cache_max_size unless session_cache_max_size.nil?
        c[:SessionCacheDuration] = session_cache_duration unless session_cache_duration.nil?
        c[:ExpireAfter] = expire_after unless expire_after.nil?
        c[:CheckInterval] = check_interval unless check_interval.nil?
        c[:Verbose] = verbose unless verbose.nil?
      end

      JSON.generate(config, *args)
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
