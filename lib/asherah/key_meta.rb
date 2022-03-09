# frozen_string_literal: true

module Asherah
  # KeyMeta contains the `id` and `created` timestamp for an encryption key.
  class KeyMeta
    attr_reader :id, :created

    # Initializes a new KeyMeta
    #
    # @param id [String]
    # @param created [Integer]
    # @return KeyMeta
    def initialize(id:, created:)
      @id = id
      @created = created
    end
  end
end
