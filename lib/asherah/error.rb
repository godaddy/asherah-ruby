# frozen_string_literal: true

module Asherah
  # Asherah Error converts the error code to error message
  module Error
    ResultError = Class.new(StandardError)

    CODES = {
      -100 => 'not initialized',
      -101 => 'already initialized',
      -102 => 'get session failed',
      -103 => 'encrypt failed',
      -104 => 'eecrypt failed'
    }.freeze

    def self.check_result!(scope, result)
      return unless result.negative?

      error_message = Error::CODES.fetch(result, 'unrecognized')
      raise Error::ResultError, "#{scope} failed: #{error_message}"
    end
  end
end
