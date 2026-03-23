# frozen_string_literal: true

require 'ffi'
require 'rbconfig'

module Asherah
  # Platform detection for native library resolution, mirroring Cobhan's logic
  module Platform
    EXTS = { 'linux' => 'so', 'darwin' => 'dylib', 'windows' => 'dll' }.freeze
    CPU_ARCHS = { 'x86_64' => 'x64', 'aarch64' => 'arm64' }.freeze
    LIB_NAME = 'libasherah'

    def self.library_file_name
      ext = EXTS[FFI::Platform::OS]
      raise "Unsupported OS: #{FFI::Platform::OS}" unless ext

      cpu_arch = CPU_ARCHS[FFI::Platform::ARCH]
      raise "Unsupported CPU: #{FFI::Platform::ARCH}" unless cpu_arch

      libc_suffix = RbConfig::CONFIG['host_os'] == 'linux-musl' ? '-musl' : ''

      "#{LIB_NAME}-#{cpu_arch}#{libc_suffix}.#{ext}"
    end
  end
end
