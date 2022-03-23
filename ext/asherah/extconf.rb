# frozen_string_literal: true

require 'mkmf'
create_makefile('asherah/asherah')

require_relative 'native_downloader'
require 'cobhan'

root_dir = File.expand_path('../../', __dir__)
file_name = Class.new.extend(Cobhan).library_file_name('libasherah')

NativeDownloader.download(root_dir, file_name)
