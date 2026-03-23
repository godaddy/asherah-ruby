# frozen_string_literal: true

require_relative 'native'

module Asherah
  # Wraps a native Asherah session for encrypt/decrypt operations on a single partition
  class Session
    def initialize(pointer)
      raise Asherah::Error::GetSessionFailed, Native.last_error if pointer.null?

      @pointer = pointer
      @closed = false
      @buffer = Native::AsherahBuffer.new
      ObjectSpace.define_finalizer(self, self.class.make_finalizer(pointer))
    end

    def encrypt_bytes(data)
      raise Asherah::Error::EncryptFailed, 'session closed' if @closed

      buf = @buffer
      status = Native.asherah_encrypt_to_json(@pointer, data, data.bytesize, buf.pointer)
      raise Asherah::Error::EncryptFailed, Native.last_error unless status.zero?

      result = buf[:data].read_bytes(buf[:len])
      Native.asherah_buffer_free(buf.pointer)
      result
    end

    def decrypt_bytes(json)
      raise Asherah::Error::DecryptFailed, 'session closed' if @closed

      buf = @buffer
      status = Native.asherah_decrypt_from_json(@pointer, json, json.bytesize, buf.pointer)
      raise Asherah::Error::DecryptFailed, Native.last_error unless status.zero?

      result = buf[:data].read_bytes(buf[:len])
      Native.asherah_buffer_free(buf.pointer)
      result
    end

    def close
      return if @closed

      ObjectSpace.undefine_finalizer(self)
      begin
        Native.asherah_session_free(@pointer)
      ensure
        @pointer = FFI::Pointer::NULL
        @closed = true
      end
    end

    def closed?
      @closed
    end

    def self.make_finalizer(pointer)
      proc do
        Native.asherah_session_free(pointer) unless pointer.null?
      rescue StandardError # rubocop:disable Lint/SuppressedException
      end
    end
  end
end
