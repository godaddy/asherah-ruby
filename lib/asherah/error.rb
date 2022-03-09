# frozen_string_literal: true

module Asherah
  # Asherah Error converts the error code to error message
  module Error
    NotInitialized = Class.new(StandardError)
    AlreadyInitialized = Class.new(StandardError)
    GetSessionFailed = Class.new(StandardError)
    EncryptFailed = Class.new(StandardError)
    DecryptFailed = Class.new(StandardError)

    CODES = {
      -100 => NotInitialized,
      -101 => AlreadyInitialized,
      -102 => GetSessionFailed,
      -103 => EncryptFailed,
      -104 => DecryptFailed
    }.freeze

    def self.check_result!(result, message)
      return unless result.negative?

      error_class = Error::CODES.fetch(result, StandardError)
      raise error_class, message
    end
  end
end
