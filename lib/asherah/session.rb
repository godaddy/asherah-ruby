# frozen_string_literal: true

require_relative 'native'

module Asherah
  # Wraps a native Asherah session for encrypt/decrypt operations on a single partition
  class Session
    def initialize(pointer)
      raise Asherah::Error::GetSessionFailed, Native.last_error if pointer.null?

      @pointer = pointer
      @closed = false
    end

    def encrypt_bytes(data)
      raise Asherah::Error::EncryptFailed, 'session closed' if @closed

      buffer = Native::AsherahBuffer.new
      status = Native.asherah_encrypt_to_json(@pointer, data, data.bytesize, buffer.pointer)
      raise Asherah::Error::EncryptFailed, Native.last_error unless status.zero?

      result = buffer[:data].read_bytes(buffer[:len])
      Native.asherah_buffer_free(buffer.pointer)
      result
    end

    def decrypt_bytes(json)
      raise Asherah::Error::DecryptFailed, 'session closed' if @closed

      buffer = Native::AsherahBuffer.new
      status = Native.asherah_decrypt_from_json(@pointer, json, json.bytesize, buffer.pointer)
      raise Asherah::Error::DecryptFailed, Native.last_error unless status.zero?

      result = buffer[:data].read_bytes(buffer[:len])
      Native.asherah_buffer_free(buffer.pointer)
      result
    end

    def close
      return if @closed

      Native.asherah_session_free(@pointer)
      @pointer = FFI::Pointer::NULL
      @closed = true
    end

    def closed?
      @closed
    end
  end
end
