# frozen_string_literal: true

require 'json'

module Asherah
  # @attr [String] kms_type
  # @attr [String] metastore
  # @attr [String] service_name
  # @attr [String] product_id
  # @attr [String] rdbms_connection_string
  # @attr [String] dynamo_db_endpoint
  # @attr [String] dynamo_db_region
  # @attr [String] dynamo_db_table_name
  # @attr [Boolean] enable_region_suffix
  # @attr [String] preferred_region
  # @attr [String] region_map
  # @attr [Boolean] verbose
  # @attr [Boolean] session_cache
  # @attr [Boolean] debug_output
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
      :verbose,
      :session_cache,
      :debug_output

    def initialize
      @verbose = false
      @session_cache = false
      @debug_output = false
    end

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
      end

      JSON.generate(config, *args)
    end
  end
end
