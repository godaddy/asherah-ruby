# frozen_string_literal: true

module Asherah
  # Asherah Error converts the error code to error message
  module Error
    ConfigError = Class.new(StandardError)
    NotInitialized = Class.new(StandardError)
    AlreadyInitialized = Class.new(StandardError)
    GetSessionFailed = Class.new(StandardError)
    EncryptFailed = Class.new(StandardError)
    DecryptFailed = Class.new(StandardError)
    BadConfig = Class.new(StandardError)

    CODES = {
      -100 => NotInitialized,
      -101 => AlreadyInitialized,
      -102 => GetSessionFailed,
      -103 => EncryptFailed,
      -104 => DecryptFailed,
      -105 => BadConfig
    }.freeze

    def self.check_result!(result, message)
      return unless result.negative?

      # Use case statement for better performance than hash lookup
      error_class = case result
                    when -100 then NotInitialized
                    when -101 then AlreadyInitialized
                    when -102 then GetSessionFailed
                    when -103 then EncryptFailed
                    when -104 then DecryptFailed
                    when -105 then BadConfig
                    else StandardError
                    end
      
      raise error_class, "#{message} (#{result})"
    end
  end
end
