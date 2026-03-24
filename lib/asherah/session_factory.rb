# frozen_string_literal: true

require_relative 'native'
require_relative 'session'

module Asherah
  # Creates native Asherah sessions for partition-based encryption
  class SessionFactory
    def initialize(pointer)
      raise Asherah::Error::BadConfig, Native.last_error if pointer.null?

      @pointer = pointer
      @closed = false
    end

    def get_session(partition_id)
      raise Asherah::Error::NotInitialized, 'factory closed' if @closed

      id = String(partition_id)
      raise ArgumentError, 'partition_id cannot be empty' if id.empty?

      Session.new(Native.asherah_factory_get_session(@pointer, id))
    end

    def close
      return if @closed

      Native.asherah_factory_free(@pointer)
      @pointer = FFI::Pointer::NULL
      @closed = true
    end

    def closed?
      @closed
    end
  end
end
