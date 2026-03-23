# frozen_string_literal: true

require 'ffi'
require_relative 'platform'

module Asherah
  # FFI bindings to the native Asherah Rust library
  module Native
    extend FFI::Library

    # Output buffer struct returned by encrypt/decrypt FFI calls
    class AsherahBuffer < FFI::Struct
      layout :data, :pointer, :len, :size_t, :capacity, :size_t
    end

    LIB_ROOT_PATH = File.expand_path('native', __dir__)

    Dir.chdir(LIB_ROOT_PATH) do
      ffi_lib File.join(LIB_ROOT_PATH, Platform.library_file_name)
    end

    attach_function :asherah_last_error_message, [], :pointer
    attach_function :asherah_factory_new_from_env, [], :pointer
    attach_function :asherah_factory_new_with_config, [:string], :pointer
    attach_function :asherah_apply_config_json, [:string], :int
    attach_function :asherah_factory_free, [:pointer], :void
    attach_function :asherah_factory_get_session, [:pointer, :string], :pointer
    attach_function :asherah_session_free, [:pointer], :void
    attach_function :asherah_encrypt_to_json, [:pointer, :buffer_in, :size_t, :pointer], :int
    attach_function :asherah_decrypt_from_json, [:pointer, :buffer_in, :size_t, :pointer], :int
    attach_function :asherah_buffer_free, [:pointer], :void

    def self.last_error
      ptr = asherah_last_error_message
      ptr.null? ? 'unknown error' : ptr.read_string
    end
  end
end
