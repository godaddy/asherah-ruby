# frozen_string_literal: true

module Asherah
  # EnvelopeKeyRecord represents an encrypted key and is the data structure used
  # to persist the key in the key table. It also contains the meta data
  # of the key used to encrypt it.
  class EnvelopeKeyRecord
    attr_reader :encrypted_key, :created, :parent_key_meta

    # Initializes a new EnvelopeKeyRecord
    #
    # @param encrypted_key [String]
    # @param created [Integer]
    # @param parent_key_meta [KeyMeta]
    # @return EnvelopeKeyRecord
    def initialize(encrypted_key:, created:, parent_key_meta:)
      @encrypted_key = encrypted_key
      @created = created
      @parent_key_meta = parent_key_meta
    end
  end
end
