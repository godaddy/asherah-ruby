
module Asherah
  module Error
    ResultError = Class.new(StandardError)

    CODES = {
      -100 => 'not initialized',
      -101 => 'already initialized',
      -102 => 'get session failed',
      -103 => 'encrypt failed',
      -104 => 'eecrypt failed'
    }

    def self.check_result!(scope, result)
      if result.negative?
        error_message = Error::CODES.fetch(result) { 'unrecognized' }
        raise Error::ResultError.new("#{scope} failed: #{error_message}")
      end
    end
  end
end
