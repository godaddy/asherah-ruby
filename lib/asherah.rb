# frozen_string_literal: true

require_relative 'asherah/version'
require 'asherah/config'
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
    [:SetupJson, [:pointer], :int32],
    [:Encrypt, [:pointer, :pointer, :pointer, :pointer, :pointer, :pointer, :pointer], :int32],
    [:Decrypt, [:pointer, :pointer, :pointer, :int64, :pointer, :int64, :pointer], :int32],
    [:EncryptToJson, [:pointer, :pointer, :pointer], :int32],
    [:DecryptFromJson, [:pointer, :pointer, :pointer], :int32],
    [:EstimateBuffer, [:int32, :int32], :int32],
    [:Shutdown, [], :void],
  ].freeze)

  KEY_BUFFER_SIZE = 60
  ESTIMATED_ENCRYPTION_OVERHEAD = 28

  class << self
    # Configures Asherah
    #
    # @yield [Config]
    # @return [void]
    def configure
      @config = Config.new
      yield @config
      @config.validate!

      # Example: _IK_user:1_gem_sable
      # The partition_id (user:1) is dynamic and added during encrypt operation
      @key_id_buffer_size_extra =
        @config.service_name.bytesize + # 'gem'
        @config.product_id.bytesize +   # 'sable'
        6                               # '_' * 4  + 'IK' or 'SK'

      config_buffer = string_to_cbuffer(@config.to_json)

      result = SetupJson(config_buffer)
      Error.check_result!(result, 'SetupJson failed')
    end

    # Encrypts data for a given partition_id and returns DataRowRecord
    #
    # @param partition_id [String]
    # @param data [String]
    # @return [DataRowRecord]
    def encrypt(partition_id, data)
      partition_id_buffer = string_to_cbuffer(partition_id)
      data_buffer = string_to_cbuffer(data)
      output_encrypted_data_buffer = allocate_cbuffer(data.bytesize + ESTIMATED_ENCRYPTION_OVERHEAD)
      output_encrypted_key_buffer = allocate_cbuffer(KEY_BUFFER_SIZE)
      output_created_buffer = int_to_buffer(0)
      output_parent_key_id_buffer = allocate_cbuffer(partition_id.bytesize + @key_id_buffer_size_extra)
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
      Error.check_result!(result, 'Encrypt failed')

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

    # Decrypts a data_row_record for a partition_id and returns decrypted data
    #
    # @param partition_id [String]
    # @param data_row_record [DataRowRecord]
    # @return [String], Decrypted data
    def decrypt(partition_id, data_row_record)
      partition_id_buffer = string_to_cbuffer(partition_id)
      encrypted_data_buffer = string_to_cbuffer(data_row_record.data)
      encrypted_key_buffer = string_to_cbuffer(data_row_record.key.encrypted_key)
      created = data_row_record.key.created
      parent_key_id_buffer = string_to_cbuffer(data_row_record.key.parent_key_meta.id)
      parent_key_created = data_row_record.key.parent_key_meta.created

      output_data_buffer = allocate_cbuffer(encrypted_data_buffer.size)

      result = Decrypt(
        partition_id_buffer,
        encrypted_data_buffer,
        encrypted_key_buffer,
        created,
        parent_key_id_buffer,
        parent_key_created,
        output_data_buffer
      )
      Error.check_result!(result, 'Decrypt failed')

      cbuffer_to_string(output_data_buffer)
    end

    def shutdown
      Shutdown()
    end

    # Encrypts data for a given partition_id and returns DataRowRecord in JSON format
    #
    # @param partition_id [String]
    # @param data [String]
    # @return [String], DataRowRecord in JSON format
    def encrypt_to_json(partition_id, data)
      partition_id_buffer = string_to_cbuffer(partition_id)
      data_buffer = string_to_cbuffer(data)
      estimated_length = EstimateBuffer(data.bytesize, partition_id.bytesize)
      output_buffer = allocate_cbuffer(estimated_length)

      result = EncryptToJson(partition_id_buffer, data_buffer, output_buffer)
      Error.check_result!(result, 'EncryptToJson failed')

      cbuffer_to_string(output_buffer)
    end

    # Decrypts a DataRowRecord in JSON format for a partition_id and returns decrypted data
    #
    # @param partition_id [String]
    # @param json [String], DataRowRecord in JSON format
    # @return [String], Decrypted data
    def decrypt_from_json(partition_id, json)
      partition_id_buffer = string_to_cbuffer(partition_id)
      data_buffer = string_to_cbuffer(json)
      output_buffer = allocate_cbuffer(json.bytesize)

      result = DecryptFromJson(partition_id_buffer, data_buffer, output_buffer)
      Error.check_result!(result, 'DecryptFromJson failed')

      cbuffer_to_string(output_buffer)
    end
  end
end
