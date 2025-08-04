# frozen_string_literal: true

module Asherah
  # Cryptographic buffer size estimation utilities
  module CryptoOperations
    private

    def estimate_buffer(data_bytesize, partition_bytesize)
      ESTIMATED_ENVELOPE_OVERHEAD +
        (@intermediated_key_overhead_bytesize || 0) +
        partition_bytesize +
        ((data_bytesize + ESTIMATED_ENCRYPTION_OVERHEAD) * BASE64_OVERHEAD)
    end
  end
end
