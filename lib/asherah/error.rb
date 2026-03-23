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
  end
end
