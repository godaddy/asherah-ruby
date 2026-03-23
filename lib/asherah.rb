# frozen_string_literal: true

require_relative 'asherah/version'
require 'asherah/config'
require 'asherah/error'
require_relative 'asherah/native'
require_relative 'asherah/session_factory'
require_relative 'asherah/session'

# Asherah is a Ruby wrapper around the Asherah application-layer encryption SDK.
module Asherah
  @mutex = Mutex.new
  @factory = nil
  @sessions = {}
  @initialized = false

  class << self
    # Set environment variables needed by Asherah dependencies.
    #
    # @param env [Hash] Key-value pairs to set in ENV
    # @return [void]
    def set_env(env = {})
      env.each_pair do |key, value|
        if value.nil?
          ENV.delete(String(key))
        else
          ENV[String(key)] = value.to_s
        end
      end
    end

    # Configures Asherah
    #
    # @yield [Config]
    # @return [void]
    def configure
      @mutex.synchronize do
        raise Asherah::Error::AlreadyInitialized if @initialized

        config = Config.new
        yield config
        config.validate!

        json = config.to_json
        pointer = Native.asherah_factory_new_with_config(json)
        @factory = SessionFactory.new(pointer)
        @sessions = {}
        @initialized = true
      end
    end

    # Encrypts data for a given partition_id and returns DataRowRecord in JSON format.
    #
    # @param partition_id [String]
    # @param data [String]
    # @return [String] DataRowRecord in JSON format
    def encrypt(partition_id, data)
      session = resolve_session(partition_id)
      session.encrypt_bytes(data)
    end

    # Decrypts a DataRowRecord in JSON format for a partition_id and returns decrypted data.
    #
    # @param partition_id [String]
    # @param json [String] DataRowRecord in JSON format
    # @return [String] Decrypted data
    def decrypt(partition_id, json)
      session = resolve_session(partition_id)
      session.decrypt_bytes(json).force_encoding(Encoding::UTF_8)
    end

    # Stop the Asherah instance
    def shutdown
      factory = nil
      sessions = nil

      @mutex.synchronize do
        raise Asherah::Error::NotInitialized unless @initialized

        factory = @factory
        sessions = @sessions.values
        @factory = nil
        @sessions = {}
        @initialized = false
      end

      sessions&.each do |session|
        session.close unless session.closed?
      rescue StandardError # rubocop:disable Lint/SuppressedException
      end
      factory&.close unless factory&.closed?
    end

    private

    def resolve_session(partition_id)
      @mutex.synchronize do
        raise Asherah::Error::NotInitialized unless @initialized

        @sessions[partition_id] ||= @factory.get_session(partition_id)
      end
    end
  end
end
