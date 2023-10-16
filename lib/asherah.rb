# frozen_string_literal: true

require_relative 'asherah/version'
require 'asherah/config'
require 'asherah/error'
require 'cobhan'

# Asherah is a Ruby wrapper around Asherah Go application-layer encryption SDK.
module Asherah
  extend Cobhan

  LIB_ROOT_PATH = File.expand_path('asherah/native', __dir__)
  load_library(LIB_ROOT_PATH, 'libasherah', [
    [:SetEnv, [:pointer], :int32],
    [:SetupJson, [:pointer], :int32],
    [:EncryptToJson, [:pointer, :pointer, :pointer], :int32],
    [:DecryptFromJson, [:pointer, :pointer, :pointer], :int32],
    [:Shutdown, [], :void]
  ].freeze)

  ESTIMATED_ENCRYPTION_OVERHEAD = 48
  ESTIMATED_ENVELOPE_OVERHEAD = 185
  BASE64_OVERHEAD = 1.34

  class << self
    # Set environment variables needed by Asherah dependencies for when
    # Go os.Getenv() doesn't see variables set by C.setenv().
    # References:
    #   https://github.com/golang/go/wiki/cgo#environmental-variables
    #   https://github.com/golang/go/issues/44108
    #
    # @yield [Config]
    # @param env [Hash], Key-value pairs to set Asherah ENV
    # @return [void]
    def set_env(env = {})
      env_buffer = string_to_cbuffer(env.to_json)

      result = SetEnv(env_buffer)
      Error.check_result!(result, 'SetEnv failed')
    end

    # Configures Asherah
    #
    # @yield [Config]
    # @return [void]
    def configure
      raise Asherah::Error::AlreadyInitialized if @initialized
      config = Config.new
      yield config
      config.validate!
      @intermediated_key_overhead_bytesize = config.product_id.bytesize + config.service_name.bytesize

      config_buffer = string_to_cbuffer(config.to_json)

      result = SetupJson(config_buffer)
      Error.check_result!(result, 'SetupJson failed')
      @initialized = true
    end

    # Encrypts data for a given partition_id and returns DataRowRecord in JSON format.
    #
    # DataRowRecord contains the encrypted key and data, as well as the information
    # required to decrypt the key encryption key. This object data should be stored
    # in your data persistence as it's required to decrypt data.
    #
    # EnvelopeKeyRecord represents an encrypted key and is the data structure used
    # to persist the key in the key table. It also contains the meta data
    # of the key used to encrypt it.
    #
    # KeyMeta contains the `id` and `created` timestamp for an encryption key.
    #
    # @param partition_id [String]
    # @param data [String]
    # @return [String], DataRowRecord in JSON format
    def encrypt(partition_id, data)
      partition_id_buffer = string_to_cbuffer(partition_id)
      data_buffer = string_to_cbuffer(data)
      estimated_buffer_bytesize = estimate_buffer(data.bytesize, partition_id.bytesize)
      output_buffer = allocate_cbuffer(estimated_buffer_bytesize)

      result = EncryptToJson(partition_id_buffer, data_buffer, output_buffer)
      Error.check_result!(result, 'EncryptToJson failed')

      cbuffer_to_string(output_buffer)
    ensure
      [partition_id_buffer, data_buffer, output_buffer].map(&:free)
    end

    # Decrypts a DataRowRecord in JSON format for a partition_id and returns decrypted data.
    #
    # @param partition_id [String]
    # @param json [String], DataRowRecord in JSON format
    # @return [String], Decrypted data
    def decrypt(partition_id, json)
      partition_id_buffer = string_to_cbuffer(partition_id)
      data_buffer = string_to_cbuffer(json)
      output_buffer = allocate_cbuffer(json.bytesize)

      result = DecryptFromJson(partition_id_buffer, data_buffer, output_buffer)
      Error.check_result!(result, 'DecryptFromJson failed')

      cbuffer_to_string(output_buffer)
    ensure
      [partition_id_buffer, data_buffer, output_buffer].map(&:free)
    end

    # Stop the Asherah instance
    def shutdown
      raise Asherah::Error::NotInitialized unless @initialized
      Shutdown()
      @initialized = false
    end

    private

    def estimate_buffer(data_bytesize, partition_bytesize)
      ESTIMATED_ENVELOPE_OVERHEAD +
        @intermediated_key_overhead_bytesize +
        partition_bytesize +
        ((data_bytesize + ESTIMATED_ENCRYPTION_OVERHEAD) * BASE64_OVERHEAD)
    end
  end
end
