# frozen_string_literal: true

require 'mkmf'
create_makefile('asherah/asherah')

require_relative 'native_file'
NativeFile.download
