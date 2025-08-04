# frozen_string_literal: true

require 'json'

module Asherah
  # Input validation methods for Asherah parameters
  module Validation
    private

    def validate_encrypt_params(partition_id, data)
      validate_string_param(partition_id, 'partition_id', 1024)
      validate_string_param(data, 'data', 100 * 1024 * 1024)
    end

    def validate_decrypt_params(partition_id, json)
      validate_string_param(partition_id, 'partition_id', 1024)
      validate_string_param(json, 'json', 10 * 1024 * 1024)
      validate_json_format(json)
    end

    def validate_string_param(value, name, max_size)
      raise ArgumentError, "#{name} cannot be nil" if value.nil?
      raise ArgumentError, "#{name} must be a String" unless value.is_a?(String)
      raise ArgumentError, "#{name} cannot be empty" if value.empty? && %w[partition_id json].include?(name)

      check_size_limit(value, name, max_size)
    end

    def check_size_limit(value, name, max_size)
      return if value.bytesize <= max_size

      if name == 'partition_id'
        raise ArgumentError, "#{name} too long (max 1KB)"
      else
        size_unit = max_size >= 1024 * 1024 ? "#{max_size / (1024 * 1024)}MB" : "#{max_size / 1024}KB"
        raise ArgumentError, "#{name} too large (max #{size_unit})"
      end
    end

    def validate_json_format(json)
      return if json.empty?

      begin
        parsed = JSON.parse(json)
        raise ArgumentError, 'json must be valid JSON format' unless parsed.is_a?(Hash)
      rescue JSON::ParserError
        raise ArgumentError, 'json must be valid JSON format'
      end
    end
  end
end
