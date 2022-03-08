# frozen_string_literal: true

module Asherah
  # DataRowRecord contains the encrypted key and data, as well as the information
  # required to decrypt the key encryption key. This object data should be stored
  # in your data persistence as it's required to decrypt data.
  class DataRowRecord
    attr_reader :data, :key

    # Initializes a new DataRowRecord
    #
    # @param data [String]
    # @param key [EnvelopeKeyRecord]
    # @return DataRowRecord
    def initialize(data:, key:)
      @data = data
      @key = key
    end
  end
end
