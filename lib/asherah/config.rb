# frozen_string_literal: true

require 'json'

module Asherah
  # @attr [String] kms_type, The master key management service (static or kms)
  # @attr [String] metastore, The type of metastore for persisting keys (rdbms, dynamodb, memory)
  # @attr [String] service_name, The name of this service
  # @attr [String] product_id, The name of the product that owns this service
  # @attr [String] rdbms_connection_string, The database connection string (required when metastore is rdbms)
  # @attr [String] dynamo_db_endpoint, An optional endpoint URL (for dynamodb metastore)
  # @attr [String] dynamo_db_region, The AWS region for DynamoDB requests (for dynamodb metastore)
  # @attr [String] dynamo_db_table_name, The table name for DynamoDB (for dynamodb metastore)
  # @attr [Boolean] enable_region_suffix, Configure the metastore to use regional suffixes (for dynamodb metastore)
  # @attr [String] preferred_region, The preferred AWS region (required for aws kms)
  # @attr [String] region_map, List of key-value pairs in the form of REGION1=ARN1[,REGION2=ARN2] (required for aws kms)
  # @attr [Integer] session_cache_max_size, The maximum number of sessions to cache
  # @attr [Integer] session_cache_duration, The amount of time in seconds a session will remain cached
  # @attr [Integer] expire_after, The amount of time in seconds a key is considered valid
  # @attr [Integer] check_interval, The amount of time in seconds before cached keys are considered stale
  # @attr [Boolean] verbose, Enable verbose logging output
  # @attr [Boolean] session_cache, Enable shared session caching
  # @attr [Boolean] debug_output< Enable debug output
  class Config
    attr_accessor  \
      :kms_type,
      :metastore,
      :service_name,
      :product_id,
      :rdbms_connection_string,
      :dynamo_db_endpoint,
      :dynamo_db_region,
      :dynamo_db_table_name,
      :enable_region_suffix,
      :preferred_region,
      :region_map,
      :session_cache_max_size,
      :session_cache_duration,
      :expire_after,
      :check_interval,
      :verbose,
      :session_cache,
      :debug_output

    def initialize
      @verbose = false
      @session_cache = false
      @debug_output = false
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def to_json(*args)
      config = {
        kmsType: kms_type,
        metaStore: metastore,
        serviceName: service_name,
        productId: product_id,
        verbose: verbose,
        sessionCache: session_cache,
        debugOutput: debug_output
      }.tap do |c|
        c[:rdbmsConnectionString] = rdbms_connection_string if rdbms_connection_string
        c[:dynamoDbEndpoint] = dynamo_db_endpoint if dynamo_db_endpoint
        c[:dynamoDbRegion] = dynamo_db_region if dynamo_db_region
        c[:dynamoDbTableName] = dynamo_db_table_name if dynamo_db_table_name
        c[:enableRegionSuffix] = enable_region_suffix
        c[:preferredRegion] = preferred_region if preferred_region
        c[:regionMapStr] = region_map if region_map
        c[:sessionCacheMaxSize] = session_cache_max_size if session_cache_max_size
        c[:sessionCacheDuration] = session_cache_duration if session_cache_duration
        c[:expireAfter] = expire_after if expire_after
        c[:checkInterval] = check_interval if check_interval
      end

      JSON.generate(config, *args)
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
