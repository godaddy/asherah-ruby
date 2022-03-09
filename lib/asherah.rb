# frozen_string_literal: true

require_relative 'asherah/version'
require 'asherah/error'
require 'asherah/key_meta'
require 'asherah/data_row_record'
require 'asherah/envelope_key_record'
require 'cobhan'

# Asherah is a Ruby wrapper around Asherah Go application-layer encryption SDK.
module Asherah
  extend Cobhan

  LIB_ROOT_PATH = File.expand_path('asherah/native', __dir__)
  load_library(LIB_ROOT_PATH, 'libasherah', [
    [
      :Setup,
      [
        :pointer, :pointer, :pointer, :pointer, :pointer, :pointer, :int32,
        :pointer, :pointer, :pointer, :pointer, :int32, :int32, :int32
      ],
      :int32
    ],
    [:Encrypt, [:pointer, :pointer, :pointer, :pointer, :pointer, :pointer, :pointer], :int32],
    [:Decrypt, [:pointer, :pointer, :pointer, :int64, :pointer, :int64, :pointer], :int32]
  ].freeze)

  class << self
    # Initializes Asherah encryption session
    #
    # @param kms_type [String]
    # @param metastore [String]
    # @param service_name [String]
    # @param product_id [String]
    # @param rdbms_connection_string [String]
    # @param dynamo_db_endpoint [String]
    # @param dynamo_db_region [String]
    # @param dynamo_db_table_name [String]
    # @param enable_region_suffix [Boolean]
    # @param preferred_region [String]
    # @param region_map [String]
    # @param verbose [Boolean]
    # @param session_cache [Boolean]
    # @param debug_output [Boolean]
    def setup(
      kms_type:,
      metastore:,
      service_name:,
      product_id:,
      rdbms_connection_string: '',
      dynamo_db_endpoint: '',
      dynamo_db_region: '',
      dynamo_db_table_name: '',
      enable_region_suffix: false,
      preferred_region: '',
      region_map: '',
      verbose: false,
      session_cache: false,
      debug_output: false
    )
      kms_type_buffer = string_to_cbuffer(kms_type)
      metastore_buffer = string_to_cbuffer(metastore)
      rdbms_connection_string_buffer = string_to_cbuffer(rdbms_connection_string)
      dynamo_db_endpoint_buffer = string_to_cbuffer(dynamo_db_endpoint)
      dynamo_db_region_buffer = string_to_cbuffer(dynamo_db_region)
      dynamo_db_table_name_buffer = string_to_cbuffer(dynamo_db_table_name)
      enable_region_suffix_int = enable_region_suffix ? 1 : 0
      service_name_buffer = string_to_cbuffer(service_name)
      product_id_buffer = string_to_cbuffer(product_id)
      preferred_region_buffer = string_to_cbuffer(preferred_region)
      region_map_buffer = string_to_cbuffer(region_map)
      verbose_int = verbose ? 1 : 0
      session_cache_int = session_cache ? 1 : 0
      debug_output_int = debug_output ? 1 : 0

      result = Setup(
        kms_type_buffer,
        metastore_buffer,
        rdbms_connection_string_buffer,
        dynamo_db_endpoint_buffer,
        dynamo_db_region_buffer,
        dynamo_db_table_name_buffer,
        enable_region_suffix_int,
        service_name_buffer,
        product_id_buffer,
        preferred_region_buffer,
        region_map_buffer,
        verbose_int,
        session_cache_int,
        debug_output_int
      )

      Error.check_result!('setup', result)
    end

    # Encrypts data for a given partition_id
    #
    # @param partition_id [String]
    # @param data [String]
    # @return [DataRowRecord]
    def encrypt(partition_id, data)
      partition_id_buffer = string_to_cbuffer(partition_id)
      data_buffer = string_to_cbuffer(data)
      output_encrypted_data_buffer = allocate_cbuffer(data.length + 256)
      output_encrypted_key_buffer = allocate_cbuffer(256)
      output_created_buffer = int_to_buffer(0)
      output_parent_key_id_buffer = allocate_cbuffer(256)
      output_parent_key_created_buffer = int_to_buffer(0)

      result = Encrypt(
        partition_id_buffer,
        data_buffer,
        output_encrypted_data_buffer,
        output_encrypted_key_buffer,
        output_created_buffer,
        output_parent_key_id_buffer,
        output_parent_key_created_buffer
      )

      Error.check_result!('encrypt', result)

      parent_key_meta = KeyMeta.new(
        id: cbuffer_to_string(output_parent_key_id_buffer),
        created: buffer_to_int(output_parent_key_created_buffer)
      )
      envelope_key_record = EnvelopeKeyRecord.new(
        encrypted_key: cbuffer_to_string(output_encrypted_key_buffer),
        created: buffer_to_int(output_created_buffer),
        parent_key_meta: parent_key_meta
      )

      DataRowRecord.new(
        data: cbuffer_to_string(output_encrypted_data_buffer),
        key: envelope_key_record
      )
    end

    # Decrypts a data_row_record for a partition_id
    #
    # @param partition_id [String]
    # @param data_row_record [DataRowRecord]
    # @return [String]
    def decrypt(partition_id, data_row_record)
      partition_id_buffer = string_to_cbuffer(partition_id)
      encrypted_data_buffer = string_to_cbuffer(data_row_record.data)
      encrypted_key_buffer = string_to_cbuffer(data_row_record.key.encrypted_key)
      created = data_row_record.key.created
      parent_key_id_buffer = string_to_cbuffer(data_row_record.key.parent_key_meta.id)
      parent_key_created = data_row_record.key.parent_key_meta.created

      output_data_buffer = allocate_cbuffer(encrypted_data_buffer.size + 256)

      result = Decrypt(
        partition_id_buffer,
        encrypted_data_buffer,
        encrypted_key_buffer,
        created,
        parent_key_id_buffer,
        parent_key_created,
        output_data_buffer
      )

      Error.check_result!('decrypt', result)

      cbuffer_to_string(output_data_buffer)
    end
  end
end
