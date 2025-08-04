# frozen_string_literal: true

require_relative 'asherah/version'
require 'asherah/config'
require 'asherah/error'
require 'asherah/validation'
require 'asherah/crypto_operations'
require 'asherah/configuration'
require 'cobhan'
require 'json'

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
    include Validation
    include CryptoOperations
    include Configuration

    def set_env(env = {})
      raise ArgumentError, 'env must be a Hash' unless env.is_a?(Hash)

      env_buffer = string_to_cbuffer(env.to_json)

      result = SetEnv(env_buffer)
      Error.check_result!(result, 'SetEnv failed')
    ensure
      env_buffer&.free
    end

    def encrypt(partition_id, data)
      raise Asherah::Error::NotInitialized unless @initialized

      validate_encrypt_params(partition_id, data)

      partition_id_buffer = string_to_cbuffer(partition_id)
      data_buffer = string_to_cbuffer(data)
      estimated_buffer_bytesize = estimate_buffer(data.bytesize, partition_id.bytesize)
      output_buffer = allocate_cbuffer(estimated_buffer_bytesize)

      result = EncryptToJson(partition_id_buffer, data_buffer, output_buffer)
      Error.check_result!(result, 'EncryptToJson failed')

      cbuffer_to_string(output_buffer)
    ensure
      [partition_id_buffer, data_buffer, output_buffer].compact.each(&:free)
    end

    def decrypt(partition_id, json)
      raise Asherah::Error::NotInitialized unless @initialized

      validate_decrypt_params(partition_id, json)

      partition_id_buffer = string_to_cbuffer(partition_id)
      data_buffer = string_to_cbuffer(json)
      output_buffer = allocate_cbuffer(json.bytesize)

      result = DecryptFromJson(partition_id_buffer, data_buffer, output_buffer)
      Error.check_result!(result, 'DecryptFromJson failed')

      cbuffer_to_string(output_buffer)
    ensure
      [partition_id_buffer, data_buffer, output_buffer].compact.each(&:free)
    end
  end
end
